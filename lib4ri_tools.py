from flask import Flask, render_template, request, make_response
from os.path import splitext, join
from os import remove
from uuid import uuid4
from subprocess import run, PIPE

SCRIPT = 'lib4ritest.sh'

async_mode = 'eventlet'

app = Flask(__name__)

@app.route("/")
def main():
    return render_template('index.html')

@app.route("/upload", methods=['GET', 'POST'])
def upload():
    filename = list(request.files)[0]
    f = request.files[filename]
    result = process_file(f)
    response = make_response(result)
    fn, ext = splitext(filename)
    resp_filename = fn + '_transformed' + ext
    response.headers["Content-Disposition"] = (
        "attachment; filename={}".format(resp_filename))
    return response

def process_file(f):
    tmpfn = join('tmp', uuid4().hex)
    f.save(tmpfn)
    cp = run([join('scripts', SCRIPT), tmpfn], stdout=PIPE)
    remove(tmpfn)
    return cp.stdout
    
if __name__ == "__main__":
    app.run(host='0.0.0.0')
    
