require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products

  test "buying a product" do
    LineItem.delete_all
    Order.delete_all
    ruby_book = products(:ruby)

    get "/"#go to the root (store index page)
    assert_response :success #did we go to the root
    assert_template "index" # are we in the index template?

    #select a product, adding it to the cart
    xml_http_request :post, '/line_items', product_id: ruby_book.id #create a new line item of ruby book. 
    assert_response :success 
    
    cart = Cart.find(session[:cart_id]) # cart should have been created when we selected rby book
    assert_equal 1, cart.line_items.size #should have the ruby book in the cart
    assert_equal ruby_book, cart.line_items[0].product # rouby book should be the first item in the cart line items

    #Checkout
    get "/orders/new" #got to new order page
    assert_response :success #did it work
    assert_template "new" #are we in the new templace

    post_via_redirect "/orders",  #generated the post request, follows any redirects unitl none are returned.
                      order: { name:     "Dave Thomas",
                               address:  "123 The Street",
                               email:    "dave@example.com",
                               pay_type: "Check" }
    assert_response :success
    assert_template "index"
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size #did the cart empty out

    #contains just our new order
    orders = Order.all #get all the orders
    assert_equal 1, orders.size #hsould have just our one
    order = orders[0] #our roder should be the first one
    
    assert_equal "Dave Thomas",      order.name  #order matches parameter set
    assert_equal "123 The Street",   order.address
    assert_equal "dave@example.com", order.email
    assert_equal "Check",            order.pay_type
    
    assert_equal 1, order.line_items.size  #only one product the ruby book selected
    line_item = order.line_items[0] #it is the first item in the order line items
    assert_equal ruby_book, line_item.product #ruby book should equal the line_item


    #mail is correctly addressed and has the correct subject line
    mail = ActionMailer::Base.deliveries.last #get the last delivery
    assert_equal ["dave@example.com"], mail.to 
    assert_equal 'Test Depot <depot@example.com>', mail[:from].value
    assert_equal "Pragmatic Store Order Confirmation", mail.subject


  end
end
