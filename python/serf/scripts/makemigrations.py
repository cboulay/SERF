def main():
    from django.core.management import call_command
    from serf.boot_django import boot_django

    # call the django setup routine
    boot_django()

    call_command("makemigrations", "serf")


if __name__ == '__main__':
    main()
