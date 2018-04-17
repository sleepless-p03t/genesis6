function checkOS() {
  var ios = !!navigator.platform && /iPad|iPhone|iPod/.test(navigator.platform);

  if (ios === true) {
    if (confirm("This isn't on a Linux Desktop.\nDo you still want to download?")) {
      return true;
    }
    return false;
  }

  if (navigator.userAgent.match(/android/i)) {
    if (confirm("This isn't on a Linux Desktop.\nDo you still want to download?")) {
      return true;
    }
    return false;
  } else if (navigator.userAgent.match(/linux/i)) {
    return true;
  }
}
