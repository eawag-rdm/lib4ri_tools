from flask import Flask, session, render_template, request, make_response, redirect, url_for, flash
from os.path import splitext, join, getmtime, getsize, relpath
from os import rename, remove, rmdir, mkdir, walk, listdir, symlink, readlink
from os import error as os_error
from shutil import copy2
from uuid import uuid4
from subprocess import run, PIPE
from collections import OrderedDict
from time import time, gmtime, strftime
from re import match, sub

# @TODO: Improve and harmonise script-handling!
SCRIPT = 'lib4ritest.sh' # This is supposed to be a wrapper-script. It will be copied to the process directory together with all the other scripts in the 'scripts' directory. Since it is called without options, it should take care to call the other scripts with the necessary parameters. It will recieve exactly one argument, namely the target file (with path relative to the process directory). The script should take care that this file is populated with the wanted data. All the data-files uploaded in the web-form will be copied in the root of the process directory (hence the other scripts should expect those files there). If some of those files need further handling (e.g. unzipping), the wrapper-script has to handle this. All this is for historical reasons. When the scripts will be re-worked, this can be done more elegantly...

async_mode = 'eventlet'

# make the reverse-proxy wrapper for path configurability
# (see, e.g., http://flask.pocoo.org/snippets/35/)
class ReverseProxied(object):
    def __init__(self, app):
        self.app = app
    def __call__(self, environ, start_response):
        script_name = environ.get('HTTP_X_SCRIPT_NAME', '')
        if script_name:
            environ['SCRIPT_NAME'] = script_name
            app.config['APPLICATION_ROOT'] = environ.get('SCRIPT_NAME') # probably needed for cookies
            path_info = environ['PATH_INFO']
            if path_info.startswith(script_name):
                environ['PATH_INFO'] = path_info[len(script_name):]
            else:
                start_response('404', [('Content-Type', 'text/html')])
                return ["Please start <a href='".encode() + script_name.encode() + "'>here</a>.".encode()]
        server = environ.get('HTTP_X_FORWARDED_SERVER', '')
        if server:
            environ['HTTP_HOST'] = server
        scheme = environ.get('HTTP_X_SCHEME', '')
        if scheme:
            environ['wsgi.url_scheme'] = scheme
        return self.app(environ, start_response)

app = Flask(__name__)
app.wsgi_app = ReverseProxied(app.wsgi_app)
app.secret_key = 'extremely_secure_random_secret_key' # @TODO: put an actual random key here...

isotimefmt = "%Y-%m-%dT%H:%M:%SZ"
expiration = float(60*5) #float(3600*1) # a float-value in seconds (1hr seems reasonable; 5 minutes might be enough)

persistent_data_folder = 'persistent_data' # stores data that persists until updated
temporary_data_folder = 'temporary_data' # stores data that will disappear after success
tmp_folder = 'tmp' # we will work in this folder
process_folder_prefix = '_'
process_folder_prefix_path = join(tmp_folder, process_folder_prefix) # we will append the session token here

target_extension = ".zip"
return_filename = "scopus" + target_extension

inst_paths = OrderedDict() # paths to institutes subfolders (make sure they exist in persistent_data_folder!!!)
inst_paths.update({'Eawag' : 'eawag'})
inst_paths.update({'Empa' : 'empa'})
inst_paths.update({'WSL' : 'wsl'})
#inst_paths.update({'PSI' : 'psi'}) # uncomment when necessary (do not forget to create the corresponding directory)
institutes = [key for key in inst_paths.keys()] # just the names
inst_spec_files = ['Authors.csv', 'Departments.csv'] # files specific to each institute

# add a file to a filelist
#
# @param OrderedDict odict
#   the filelist to add to
# @param str inst
#   the institute to which the file should be added
# @param str file
#   the filename of the file
# @param str dir
#   the directory that will contain the file
#
# Note: the structure of the resulting filelist is as follows:
#   inst -> file -> {'name' : file, 'path' : path}
# where inst takes different institute-names as values, or '*' for
# the shared files, or '.' for the temporary files, and file takes on
# as values the different filenames.
# Below, we are going to add a third key-val pair to each file, namely
# {'date' : UTC-datestring}, to store the times of last update
def add_file_to_filelist(odict, inst, file, dir):
    fileodict = OrderedDict({file : OrderedDict({'name' : file})})
    fileodict[file].update(OrderedDict({'path' : join(dir, file)}))
    if inst not in odict: # if we add to this inst for the first time
        odict.update({inst : fileodict})
    else:
        odict[inst].update(fileodict)

static_files = OrderedDict() # the final filelist of non-temporary files
for inst in institutes:
    for file in inst_spec_files:
        add_file_to_filelist(static_files, inst, file, join(persistent_data_folder, inst_paths[inst]))

add_file_to_filelist(static_files, '*', 'Journals.csv', persistent_data_folder) # a file shared across institutes
add_file_to_filelist(static_files, '*', 'OpenAccess_Info.csv', persistent_data_folder) # a file shared across institutes

files = static_files # the final filelist (static (=specific&shared) and temporary)
add_file_to_filelist(files, '.', 'WOS.txt', temporary_data_folder) # a temporary file
add_file_to_filelist(files, '.', 'PDFs.zip', temporary_data_folder) # a temporary file
add_file_to_filelist(files, '.', 'scopus.xml', temporary_data_folder) # a temporary file

# remove temporary files
def rmtmpfiles():
    global files
    for file in files['.']:
        remove(files['.'][file]['path'])
    update_files_times()

# update the times of last modification of the final filelist
def update_files_times():
    global files
    for inst in files:
        for file in files[inst]:
            try:
                date = strftime(isotimefmt, gmtime(getmtime(files[inst][file]['path'])))
            except os_error: # file not found or inaccessible
                date = False
            files[inst][file].update({'date' : date})
update_files_times()

# get the file-paths used by a specific inst-value
#
# @param str inst
#   the name of the institute
#
# @return list
#   the list of file-paths corresponding to the given institute, including
#   shared and temporary files
def get_used_files_paths(inst):
    result = []
    for i in [inst, '*', '.']:
        if i in files:
            for f in files[i]:
                result.append(files[i][f]['path'])
    return result

# get the process-folder for the primary token (given or current)
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# @return str | None
#   the process-folder for the primary token corresponding to the given one,
#   or None if there is no corresponding primary token
#
# Note: see get_primary_token() for an explanation
def get_process_folder(token = None): # accepts a token or a list of tokens
    tok = get_primary_token(token)
    if not tok:
        return None
    return process_folder_prefix_path + tok


# get the target file for the primary token (given or current)
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# @return str | None
#   the target file for the primary token corresponding to the given one,
#   or None if there is no corresponding primary token
#
# Note: target_file is the file containing the data returned by the script
# Note: see get_primary_token() for an explanation
def get_target_file(token = None): # accepts a token or a list of tokens
    tok = get_primary_token(token)
    if not tok:
        return None
    return join(tmp_folder, tok) + target_extension

# make a json string out of an object
#
# @param mixed obj
#   an object to be made a string and properly wrapped + escaped for json
#
# @return str
#   the str(obj)-string with newlines and double-quotes properly escaped and
#   wrapped in quotes
def mkjsonstr(obj):
    return '"' + str(obj).replace('\r','').replace('\n', '\\\\n').replace('"', '\\\\"') + '"'

# jsonise lists and ordered dictionaries
#
# @param mixed odict
#   an object to be recursively jsonised
#
# @return str
#   a json-string
#
# @TODO
#   the function currently only works with the following types:
#     None, bool, int, float, str, list, OrderedDict
#   it could be useful to extend to other types...
def jsonize_nested_odicts(odict): # @TODO: make this work with more data types!
    if odict is None or isinstance(odict, (bool, int, float)):
        return str(odict)
    if isinstance(odict, str):
        return mkjsonstr(odict)
    if isinstance(odict, list):
        return '[' + ', '.join([jsonize_nested_odicts(val) for val in odict]) + ']'
    if isinstance(odict, (dict, OrderedDict)):
        return '{' + (', '.join('{} : {}'.format(jsonize_nested_odicts(key), jsonize_nested_odicts(val)) for key, val in odict.items())) + '}'
    raise TypeError("Cannot (yet) jsonize type %s" % type(odict))

# make a token-list with the active token on 2nd position
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# @return list
#   a list of tokens with the first given token in first position, and the rest
#   at positions 3ff, second position being given to the current active token
def mktoks(token = None): # takes a token or a list of tokens (where the first one takes precedence)
     if not isinstance(token, list):
         token = [token]
     return [token[0], activetoken] + token[1:]

# get the primary token corresponding to the given (list of) token(s)
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# @return str | None
#   the corresponding primary token, or None if there is not any
#
# Note: given a (list of) token(s) [tokA, tokB, ...], this functions chooses
# the first non-None token from the list [tokA, ACTTOK, tokB, ...], where
# ACTTOK is the current active token (or None, if there is no active session).
def get_primary_token(token = None): # takes a token or a list of tokens
    tok = None
    toks = mktoks(token)
    for t in toks:
        if t:
            tok = t
            break
    return tok

# get the token file for the primary token (given or current)
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# @return str | None
#   the token file for the primary token corresponding to the given one,
#   or None if there is no corresponding primary token
#
# Note: the token file is used to store sessions in the file system
# Note: see get_primary_token() for an explanation
def get_tokenfile(token = None): # takes a token or a list of tokens
    tok = get_primary_token(token)
    return join(tmp_folder, tok) if tok else None

# make a new session if None is given or update the session for the 
# primary token corresponding to the given token (list)
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# @return str
#   the token of the new (or updated) session
#
# Note: this updates the file-time of the token file, as well as the session
# variable
def mknewsession(token = None): # N.B.: This does not seperately check for existence of an old one...; takes a token or a list of tokens
    if not token or not get_primary_token(token):
        token = uuid4().hex
    else:
        token = get_primary_token(token)
    tokfil = get_tokenfile(token)
    with open(tokfil, 'w') as f: # this should update the mtime (or create the file if it does not exist)
        f.close()
    session['token'] = token
    session['time'] = time()
    return token

activetoken_symlinkname = 'activetoken' # the name of the symlink to the file for the active token

# makes the session for the (given or current) token active
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# Note: active means, that this session can handle the files and execute the
# scripts, while all the others can not (they can kill the active session once
# it is expired, though)
def activatesession(token = None): # takes a token or a list of tokens
    global activetoken, activetime
    activetoken = get_primary_token(token)
    if not activetoken:
        print("Warning: Cannot activate session, because I did not receive any token")
        return
    activetime = time()
    try:
        remove(join(tmp_folder, activetoken_symlinkname))
    except FileNotFoundError: # the symlink does not (yet) exist; that is o.k.
        pass
    symlink(get_primary_token(token), join(tmp_folder, activetoken_symlinkname))

# remove the sessions for the given token list, in addition to the active one
# as well as expired ones
#
# @param None | str | list(str)
#   a token or a list of tokens or None
def rmoldsession(token = None): # takes a token or a list of tokens
    global activetoken, activetime
    alltokens = mktoks(token)
    toremove = [activetoken_symlinkname]
    for tt in alltokens:
        if tt and tt not in toremove:
            toremove.append(tt)
    for t in toremove:
      tokfil = get_tokenfile(t)
      if tokfil:
          try:
              remove(tokfil)
          except FileNotFoundError: # seems we already deleted that file...
              print("Warning: attempt to remove non-existent file '", tokfil, "'; it is probably safe to ignore this message.")
              pass
    activetoken = None
    activetime = None
    session['token'] = None
    session['time'] = None
    session.clear()
    remove_expired_sessions() # clean-up other sessions

activetoken = None
activetime = None

# get the session token and session time
#
# @return str | None, str | None
#   the session token and session time (each might be None if non-existent)
def get_session_info(): # returns sessiontoken, sessiontime
    try:
        sessiontoken = session['token']
    except KeyError:
        sessiontoken = None
    if sessiontoken == '':
        sessiontoken = None
    try:
        sessiontime = session['time']
    except KeyError:
        sessiontime = None
    if sessiontime == '':
        sessiontime = None
    if sessiontoken and not sessiontime:
        print("Warning: Got session without time: ", sessiontoken)
    return sessiontoken, sessiontime

# get the time of the token file for the (given or current) token
#
# @param None | str | list(str)
#   a token or a list of tokens or None
#
# @return str | None
#   the time of the token file for the primary token corresponding to the
#   given (list of) token(s)
def get_tokentime(token = None): # accepts one token or a list of tokens
    tokfil = get_tokenfile(token)
    if not tokfil:
        return None
    try:
        toktim = getmtime(tokfil)
    except os_error:
        print("Warning: Could not stat '", tokfil, "'")
        toktim = None
    return toktim

# recursively remove directories and their content
#
# @param str dir
#   the path in which to remove all files and subdirectories
#
# @CAVEAT: this function does not perform any checks and might
# easily wipe your system! Use with caution and at your own risk!
def recursive_rmdir(dir): # @NOTE: This does not do any checks! Use with caution or lose data!
    for rootdir, subdirs, files in walk(dir, topdown=False): # from the example in the os.walk() documentation
        for f in files:
            remove(join(rootdir,f))
        for d in subdirs:
            rmdir(join(rootdir,d))
    rmdir(dir)

# remove all expired sessions save those in the given exclusion list
#
# @param None | str | list(str)
#   a token or a list of tokens to exclude, or None
#
# Note: this will not remove the files for the given (list of) token(s), nor
# the one corresponding to the active token, nor the one pointed at by the
# activetoken_symlinkname symbolic link
def remove_expired_sessions(xtoks=None): # accepts one token or a list of tokens to exclude
    if not isinstance(xtoks, list):
        xtoks = [xtoks]
    now = time()
    atokfil = None
    try:
        atokfil = readlink(join(tmp_folder, activetoken_symlinkname))
    except FileNotFoundError: # the symlink does not (yet) exist; this is o.k.
        pass
    toks = [f for f in listdir(tmp_folder) if match('^[0-9a-f]{32}$', f) and f not in [atokfil, activetoken] + xtoks]
    for tok in toks:
        tokfil = get_tokenfile(tok)
        t = get_tokentime(tok)
        if t and now - t > expiration:
            print("Notice: Removing expired session: ", tok)
            remove(tokfil)
    remaining_toks = [f for f in listdir(tmp_folder) if match('^[0-9a-f]{32}$', f)]
    tokdirs = [join(tmp_folder, d) for d in listdir(tmp_folder) if match('^' + process_folder_prefix + '[0-9a-f]{32}$', d) and d[len(process_folder_prefix):] not in remaining_toks]
    for dir in tokdirs:
        if dir[:len(tmp_folder)] != tmp_folder or len(dir[len(tmp_folder):]) <= 0: # just be extra-sure...
            print("Warning: Skipping deletion of directory '", dir, "'")
            continue
        print("Notice: Removing unused process directory '", dir, "'")
        recursive_rmdir(dir)
    for f in [get_target_file(t[:32]) for t in listdir(tmp_folder) if match('^[0-9a-f]{32}' + target_extension + '$', t) and t[:32] not in remaining_toks]:
        print("Notice: Removing unused target file '", f, "'")
        remove(f)

# handles the sessions
#
# @return bool
#   True, if a new session has been started and activated, False if another
#   active session exists
def session_handler(): # returns True if starting a new session, or False if another session exists. @TODO: Handle session and form times, as well
    global activetoken, activetime
    sessiontoken, sessiontime = get_session_info()
    remove_expired_sessions(sessiontoken)
    sessiontoken = mknewsession(sessiontoken)
    now = time()
    toks = [None, sessiontoken] # prioritise activetoken, then sessiontoken
    tokfil = get_tokenfile(toks)
    if tokfil:
        activetime = get_tokentime(toks)
        if not activetime: # file does not exist (or is inaccessible); we assume we need to create a new session
            if get_primary_token(toks) != sessiontoken: # if we have not removed the old session in this session
                print("Warning: Might encounter competing requests between", get_primary_token(toks), "and", sessiontoken)
            if not activetoken:
                print("Notice: Activating new session:", sessiontoken)
                activatesession(get_primary_token(sessiontoken))
            return (activetoken == sessiontoken)
    token = activetoken
    if not token: # this should only happen on the first request since the server started
        try: # check if there is an old active session
            token = readlink(join(tmp_folder, 'activetoken'))
        except FileNotFoundError:
            token = sessiontoken # re-use the old session, if it exists
            pass
        else:
            activetime = get_tokentime(token)
            if not activetime: # the symlink probably points to a non-existent file
                print("Warning: Someone seems to have tampered with the temporary directory where I keep track of session tokens...")
                token = sessiontoken
            else:
                activetoken = token
                print("Notice: Found existing active session:", token)
    if sessiontoken != token: # a separate request...
        return False
    activatesession(token)
    return True

# retrieve the document root (w/out servername and w/out trailing slash)
def get_docroot():
    root = "/"
    try:
        root = request.environ['SCRIPT_NAME']
    except KeyError:
        pass
    root = sub("/$", "", root) # remove trailing slash
    return root

# render the page that says that another session is active
def render_occupied():
    sessiontoken, sessiontime = get_session_info()
    return render_template('tokenerror.html',
      docroot  = jsonize_nested_odicts(get_docroot()),
      oldtoken = jsonize_nested_odicts(activetoken),
      newtoken = jsonize_nested_odicts(sessiontoken),
      expires  = jsonize_nested_odicts(strftime(isotimefmt, gmtime(activetime + expiration))),
    )

@app.route("/")
# render the main page (re-routing when necessary)
def main():
    global activetokenisdone
    try: # we start be cleaning up if we just processed
        activetokenisdone
    except NameError: # the variable is undefined and we proceed normally
        pass
    else:
        rmtmpfiles()
        rmoldsession()
        del activetokenisdone
        return "Thank you for using this service!"
    sessiontoken, sessiontime = get_session_info()
    if not session_handler(): # another session is active
        return render_occupied()
    selected_institute = None
    if 'institute' in request.args and request.args['institute'] in institutes: # also react to GET requests
        selected_institute = request.args['institute']
    if 'institute' in request.form and request.form['institute'] in institutes:
        selected_institute = request.form['institute']
    update_files_times()
    return render_template('index.html',
      docroot    = jsonize_nested_odicts(get_docroot()),
      institutes = jsonize_nested_odicts(institutes),
      files      = jsonize_nested_odicts(files),
      institute  = jsonize_nested_odicts(selected_institute),
      token      = jsonize_nested_odicts(activetoken),
    )

@app.route("/upload", methods=['GET', 'POST'])
# handle the upload and display the main page (re-routing when necessary)
def upload():
    if not session_handler():
        return render_occupied()
    error = False
    for filename in request.files:
        if request.files[filename].filename == '':
            continue
        if not process_file(request.files[filename]):
            error = True
    if error:
        flash("Something went wrong while trying to save the uploaded files...")
    return main()

# processes the uploaded file (well, saves it...)
#
# @param file f
#   the uploaded file
#
# @return bool
#   True on success, False otherwise
#
# @TODO
#   Re-assess the error handling...
def process_file(f): # @TODO: Error handling
    tmpfn = join(tmp_folder, f.name)
    f.save(tmpfn)
    ri = request.form['institute']
    rn = f.name
    fn = False
    tmpfiles = OrderedDict()
    for key in (set(files.keys()) & set([ri, '*', '.'])):
        tmpfiles.update({key : OrderedDict()})
    for inst in tmpfiles:
        tmpfiles[inst] = files[inst]
    for inst in tmpfiles:
        for file in tmpfiles[inst]:
            if rn == file:
                fn = tmpfiles[inst][file]['path']
    if fn: # we copy2+remove instead of rename in case we cross file systems (e.g. when tmp_folder is mounted as ramdisk)
        copy2(tmpfn, fn)
        remove(tmpfn)
    return (fn is not False)

@app.route("/process", methods=['GET', 'POST'])
# process the files (execute the script) and re-direct to main page
# (re-route when necessary)
def process():
    if not session_handler():
        flash("It seems your session has expired and another user took over")
        return render_occupied()
    selected_institute = None
    if 'institute' in request.args and request.args['institute'] in institutes:
        selected_institute = request.args['institute'] # also react to GET requests
    if 'institute' in request.form and request.form['institute'] in institutes:
        selected_institute = request.form['institute']
    update_files_times()
    if selected_institute in institutes and all([files[selected_institute][file]['date'] for file in files[selected_institute]]) and all([files['*'][file]['date'] for file in files['*']]) and all([files['.'][file]['date'] for file in files['.']]): # every file needed for this institute is present
        process_folder = get_process_folder()
        try:
            getmtime(process_folder)
        except os_error: # process directory does not exist yet
            try:
                mkdir(get_process_folder())
            except os_error: # this should never happen!!
                print("Warning: Could not create process directory!")
                flash("An internal error occured. Please notify the maintainers")
                return redirect(url_for('main'))
#        cp = run([join('scripts', SCRIPT), files[selected_institute]["Authors.csv"]['path']], stdout=PIPE, stderr=PIPE)
        if not prepare_script_execution(selected_institute):
            print("Warning: Could not prepare script execution!")
            flash("An internal error occured. Please notify the maintainers")
            return redirect(url_for('main'))
        cp = run([join('.', SCRIPT), relpath(get_target_file(), start=process_folder)], stdout=PIPE, stderr=PIPE, cwd=process_folder)
        recursive_rmdir(process_folder)
        return render_template('process.html',
          docroot  = jsonize_nested_odicts(get_docroot()),
          success  = jsonize_nested_odicts(True),
          filename = jsonize_nested_odicts(return_filename),
          nexturl  = jsonize_nested_odicts(url_for('main')),
          stdout   = jsonize_nested_odicts(cp.stdout.decode("utf-8")),
          stderr   = jsonize_nested_odicts(cp.stderr.decode("utf-8")),
        )
    else:
        flash("Could not process the files. Perhaps some files are missing? Note: Do not reload the page nor use the back button!")
    return redirect(url_for('main'))

# prepare the execution of the script for the given institute
#
# @param str inst
#   the institute for which the script should be executed
#
# @return str | False
#   the stdout, stderr of the executed script, of False if the execution
#   could not be prepared (e.g. b/c of a missing file)
def prepare_script_execution(inst):
    if inst not in institutes:
        return False
    process_folder = get_process_folder()
    for s in listdir('scripts'):
        copy2(join('scripts', s), process_folder)
    for i in [inst, '*', '.']:
        for file in files[i]:
            copy2(files[i][file]['path'], process_folder)
    return True

@app.route("/retrieve", methods=['POST'])
# retrieves the target file (re-routes when necessary)
def retrieve():
    global activetokenisdone # will be set to True if we deliver the result
    sh_result = session_handler()
    sessiontoken, sessiontime = get_session_info()
    if not sh_result:
        flash("It seems your session has expired and another user took over.")
        return render_occupied()
    filename = None
    if 'filename' in request.form:
        filename = request.form['filename']
    if not filename or filename == '':
        filename = return_filename
    target_file = get_target_file([None, sessiontoken]) # prioritise activetoken, then sessiontoken
    if not target_file or not sessiontoken or sessiontoken != activetoken:
        print("Warning: Possible meddling attempt of", activetoken, "by", sessiontoken, "in", target_file)
        flash("Your request for file retrieval was ill set. I am starting you over...")
        return redirect(url_for('main'))
    result = None
    try:
        with open(target_file, "rb") as f:
            result = f.read()
            f.close()
    except os_error:
        flash("The file you requested does not exist (perhaps you reloaded this page or used the back button?). I am starting you over...")
        return redirect(url_for('main'))
    response = make_response(result)
    response.headers["Content-Type"] = "application/octet-stream"
    response.headers["Content-Disposition"] = (
        "attachment; filename={}".format(filename))
    activetokenisdone = True
    return response

@app.route("/reset", methods=['POST'])
# performs the session reset
def reset():
    if session_handler():
        flash("The server does not need resetting...")
        return redirect(url_for('main'))
    sessiontoken, sessiontime = get_session_info()
    oldtoken = None
    newtoken = None
    if 'oldtoken' in request.form:
        oldtoken = request.form['oldtoken']
    if oldtoken == '':
        oldtoken = None
    oldtokentime = get_tokentime(oldtoken)
    if 'newtoken' in request.form:
        newtoken = request.form['newtoken']
    if newtoken == '':
        newtoken = None
    if oldtoken and activetoken and oldtoken == activetoken and newtoken == sessiontoken and oldtokentime and time() - oldtokentime > expiration:
        rmoldsession()
        sessiontoken = mknewsession(sessiontoken)
        activatesession(sessiontoken)
        flash("Server reset successful. Your session is now active.")
    else:
        print("Warning: Attempt to reset server failed. Got (activetoken, sessiontoken, oldtoken, newtoken) = ", activetoken, sessiontoken, oldtoken, newtoken)
        flash("Could not reset server. Probably the other user got active meanwhile.")
    return redirect(url_for('main'))

if __name__ == "__main__":
    app.run(host='0.0.0.0')

