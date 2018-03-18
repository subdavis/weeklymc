# Weekly Minecraft

Set up scheduling with https://docs.aws.amazon.com/solutions/latest/instance-scheduler/welcome.html

# Config

The config files in `config/` will be updated on the server at the beginning of each session.  To update these, please submit a pull request.

# Useful commands

```sh
docker run --rm -it \
	--name mc \
	-e AWS_ACCESS_KEY_ID=CHANGE \
	-e AWS_SECRET_ACCESS_KEY=CHANGE 
	mc
```