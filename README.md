<div align="center">

# ⭐ Give me a star, please! ⭐

<img src="https://raw.githubusercontent.com/francescobianco/gif/main/images/give-stars-h192.gif" /><img src="https://raw.githubusercontent.com/francescobianco/gif/main/images/push-button-h192.gif" />

</div>

---

# 🔔 inotifywait (with polling)

[![Build Status](https://travis-ci.org/javanile/inotifywait-polling.svg?branch=master)](https://travis-ci.org/javanile/inotifywait-polling)
[![codecov](https://codecov.io/gh/javanile/inotifywait-polling/branch/master/graph/badge.svg)](https://codecov.io/gh/javanile/inotifywait-polling)

Today **inotify** has limitaions on watch for chagnes into particular filesystem or mount point. Here is a short list

- Mountend volumes from Docker containers in a Microsoft Windows host.
- Mountend directories with file system SMB/NFS from GNU/Linux host.

In all of this cases you can use **inotifywait-polling** instead of classic **inotifywait** to watch for changes into the above scenarious.

## Install

The most common way to install the project is from GitHub source

```shell
git clone https://github.com/javanile/inotifywait-polling.git
sudo cp ./inotifywait-polling/inotifywait-polling.sh /usr/local/bin/inotifywait-polling
chmod +x /usr/local/bin/inotifywait-polling
```

## Usage

It works exactly like the original, so it accepts the same options, with the only difference that it checks every 5 seconds that your target has changed or not (unfortunately this is the only way around the problem in those file systems where the original does not work).

```shell
$ inotifywait-polling $HOME
Setting up watches.
Watches established.
```

### Dockerfile

```bash
RUN curl -s https://raw.githubusercontent.com/javanile/inotifywait-polling/main/setup.sh | bin=inotifywait bash -
```

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Testing

```bash
$ make install
```

```bash
$ make tdd take=tests/HamperDatabaseTest.php 
```

## Contributing

Please see [CONTRIBUTING](CONTRIBUTING.md) for details.

## Security

If you discover any security related issues, please email bianco@javanile.org instead of using the issue tracker.

## Socialware

We highly appreciate if you create a social post on Twitter by clicking the following button

[![Share on Twitter](https://img.shields.io/badge/-share%20on%20twitter-blue?logo=twitter&style=for-the-badge)](https://twitter.com/intent/tweet?text=Hello%20world)

## Credits

This project exists thanks to all the people who contribute.

- [Francesco Bianco](https://github.com/francescobianco)
- [All Contributors](https://github.com/javanile/hamper/graphs/contributors) 

## Support us

Javanile is a community project agency based in Sicily, Italy. 
You'll find an overview of all our projects [on our website](https://www.javanile.org).

Does your business depend on our contributions? Reach out us on [Patreon](https://www.patreon.com/javanile). 

## License

The MIT License (MIT). Please see [License File](https://github.com/javanile/hamper/blob/main/LICENSE) for more information.
