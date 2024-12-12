FROM amazon/aws-lambda-python:3.10

COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

COPY authorizer.py ${LAMBDA_TASK_ROOT}

CMD ["authorizer.handler"]