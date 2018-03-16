# Weekly Minecraft

# Useful commands

```sh
docker run --rm -it \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
	-e STARTCRON="00 19 * * 2" \
	-e STOPCRON="00 21 * * 2" \
	mc
```