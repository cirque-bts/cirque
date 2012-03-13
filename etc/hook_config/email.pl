{
    default => {
        'Email::Send' => {
            mailer => 'Sendmail',
        },
        base_url => 'http://bts.example.com',
        mail_from => 'cirque@bts.example.com',
    },
    dev => {
        'Email::Send' => {
            mailer => 'Sendmail',
        },
        base_url => 'http://bts.example.com',
        mail_from => 'cirque@bts.example.com',
    },
    production => {
        'Email::Send' => {
            mailer => 'Sendmail',
        },
        base_url => 'http://bts.example.com',
        mail_from => 'cirque@bts.example.com',
    },
};

