# SystemRescue Image Builder
A [Docker][docker]-based solution for creating customized
[SystemRescue][systemrescue] images.
Building a SystemRescue image requires an [Arch Linux][arch] environment,
which may be a show-stopper for users of other distributions.
By using Docker, we can quickly create a temporary Arch Linux environment
to build SystemRescue.
More importantly, this allows us to customize the functionality of
SystemRescue, by packing our [SystemRescue modules][srm] (SRMs) in
the produced iso image.

## Use-case
SystemRescue is great for personal use by experienced users.
However, if you want to provide remote recovery help to an inexperienced
friend or client, guiding them through the steps can be slow and
frustrating.
With SystemRescue Image Builder, it becomes trivial to build a customized
image that once booted, it will give you quick access to the remote
system/network without requiring the usual step-by-step guidance.

## Requirements

* You will neeed to have a working Docker installation, and to be able to
  run containers in privileged mode.
  Privileged mode is required because [pacstrap][pacstrap] needs to
  be able to create priviled mounts (such as `proc` or `sys`) for the
  fakeroot environment.
* The Docker image used for building SystemRescue requires around 790MB
  of disk space.
* During the creation of a vanilla SystemRescue image, the Docker
  container will use around 4.5GB of additional disk space.
  Additional disk space may be required, depending on the size of
  your [SRMs][srm].
* QEMU and zsh are required for test-booting the produced SystemRescue

  image.

## Basic usage
For creating a simple SystemRescue image that automatically connects
to your [Wireguard][wg] server and allows ssh access, follow these
steps:

```bash
# copy files for ssh_keys SRM
cp ~/.ssh/id_*.pub modules/ssh_keys

# copy files for wg_client SRM
...

# build Docker image
make

# build SystemRescue image
...

# test SystemRescue image
./scripts/qemu-test.sh systemrescue-8.03-amd64.iso
```

**Pro-tip:**
Instead of flashing the produced iso on the USB/sd-card every time,
it is recommended to format the medium once with [Ventoy][ventoy].
After that step, you can simply dump any iso file you want to boot
in the storage medium and select it via the Ventoy boot menu.
At the same time, the storage medium remains usable, without having
to re-format it after finishing working with SystemRescue.

## Including custom modules in the SystemRescue image
SystemRescue modules are created by the contents of the `SRM_SRC_LOCAL`
directory. Only the modules selected via the `SRM_ENABLED` Makefile
variable are processed. The processing steps are:

* Copying the contents of the module directories in the Docker image.
* Installing packages required by each module in the Docker image.
  The packages are listed in `packages.txt` file of each module.
* Running the `bootstrap.sh` script. This script is expected to
  populated the `srm` directory for each module.
* Creating a single `.srm` file from all the `srm` directories
  created.
  Currently, SystemRescue doesn't support selectively loading SRMs.
  So, it is preferred to create a single `.srm` file, rather than
  one per module.

By default, files of the SRM modules are owned by `root:root` and their
permissions are preserved. If you need to set different ownership or
permissions, you need to apply them via your `bootstrap.sh` script.


## Caveats
* Currently, only building of x86\_64 images is supported.
* You will need to be able to run containers in privileged mode.
  This may not be allowed in shared environments.

[arch]: https://archlinux.org/
[docker]: https://www.docker.com/
[pacstrap]: https://man.archlinux.org/man/pacstrap.8
[systemrescue]: https://www.system-rescue.org/
[srm]: https://www.system-rescue.org/Modules/
[ventoy]: https://www.ventoy.net/en/index.html
[wg]: https://www.wireguard.com/
