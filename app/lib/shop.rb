# Static information about the shop: contact details and social profiles.
#
# These are configuration, not content: they are the same on every page and
# are not edited from the admin panel (that is a later phase). Keeping them
# here means the views never hardcode phone numbers or URLs.
module Shop
  module_function

  # Contact phone numbers, shown in the footer.
  def phones
    {
      bertamirans: { label: "Bertamiráns", number: "981 939 352", tel: "+34981939352" },
      noia: { label: "Noia", number: "981 825 630", tel: "+34981825630" }
    }
  end

  # Email address shown in the footer.
  def email
    "silvaldehogar@gmail.com"
  end

  # Social profiles shown in the footer.
  def social_links
    {
      instagram: { name: "Instagram", url: "https://www.instagram.com/silvalde.hogar/" },
      facebook: { name: "Facebook", url: "https://www.facebook.com/silvalde-hogar" }
    }
  end
end
