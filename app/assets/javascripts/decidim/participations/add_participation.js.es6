$(() => {
  window.DecidimParticipations = window.DecidimParticipations || {};

  window.DecidimParticipations.bindParticipationAddress = () => {
    const $checkbox = $('#participation_has_address');
    const $addressInput = $('#address_input');

    if ($checkbox.length > 0) {
      const toggleInput = () => {
        if ($checkbox[0].checked) {
          $addressInput.show();
        } else {
          $addressInput.hide();
        }
      }
      toggleInput();
      $checkbox.on('change', toggleInput);
    }
  };

  window.DecidimParticipations.bindParticipationAddress();
});
