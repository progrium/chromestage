FROM golang:1.21-alpine as builder
WORKDIR /chromestage

COPY go.mod .
COPY go.sum .

RUN apk add --no-cache ca-certificates git

# Get dependancies - will also be cached if we won't change mod/sum
RUN go mod download

COPY main.go .
RUN CGO_ENABLED=0 GOARCH=amd64 go install -installsuffix "static" .

#########

FROM ubuntu:jammy
ENV LANG="C.UTF-8"

# install utilities
RUN apt-get update
RUN apt-get -y install wget --fix-missing
RUN apt-get -y install xvfb xorg x11vnc firefox xterm dbus-x11 xfonts-100dpi xfonts-75dpi xfonts-cyrillic --fix-missing # chrome will use this to run headlessly
RUN apt-get -y install unzip xterm --fix-missing
RUN apt-get -y install pulseaudio
RUN apt-get -y install ffmpeg

RUN adduser root pulse-access

# install go
RUN wget -O - 'https://storage.googleapis.com/golang/go1.21.3.linux-amd64.tar.gz' | tar xz -C /usr/local/
ENV PATH="$PATH:/usr/local/go/bin"

# install dbus - chromedriver needs this to talk to google-chrome
RUN apt-get -y install dbus --fix-missing
RUN apt-get -y install dbus-x11 --fix-missing
#RUN ln -s /bin/dbus-daemon /usr/bin/dbus-daemon     # /etc/init.d/dbus has the wrong location
#RUN ln -s /bin/dbus-uuidgen /usr/bin/dbus-uuidgen   # /etc/init.d/dbus has the wrong location

# install chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
RUN apt-get update
RUN apt-get -y install google-chrome-stable

# install chromedriver
# NOTE: this is a relatively old version.  Try a newer version if this does not work.
RUN wget -N http://chromedriver.storage.googleapis.com/2.25/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN chmod +x chromedriver
RUN mv -f chromedriver /usr/local/bin/chromedriver

ENV DISPLAY=:99
ENV XVFB_WHD=1280x720x24

# VNC
EXPOSE 5900
# chromedp
EXPOSE 9222

RUN groupadd -r chromium && useradd -r -g chromium -G audio,video,pulse-access chromium \
  && mkdir -p /home/chromium/Downloads && chown -R chromium:chromium /home/chromium

RUN apt-get install -y ca-certificates tzdata
COPY --from=builder /go/bin /bin
COPY /start.sh /home/chromium/start.sh
RUN chmod +x /home/chromium/start.sh

# Run as non privileged user
USER chromium
WORKDIR /home/chromium
ENTRYPOINT ["/home/chromium/start.sh"]
