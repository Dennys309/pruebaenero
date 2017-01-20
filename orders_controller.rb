class OrdersController < ApplicationController
  
  include CurrentRegistro
  before_action :set_registro, only: [:new, :create]
  before_action :set_order, only: [:show, :edit, :destroy]
  
  def index
	  @orders = Order.all 
	end
	
	def new
		if @registro.curso_items.empty?
			redirect_to shop_url, notice: 'Tu Registro esta VACIO'
			return
		end
		@order = Order.new
		@client_token = Braintree::ClientToken.generate
	end
	
	def create
		@order = Order.new(order_params)
		if @order.save
			charge
			if @result.success?
				@order.add_curso_items_from_registro(@registro)
				Registro.destroy(session[:registro_id])
				session[:registro_id] = nil
				OrderNotifier.received(@order).deliver 
				redirect_to root_url, notice: 'Gracias por tu Inscripcion!'
			else
				flash[:error] = 'Revisa tu Registro'
				redirect_to root_url, alert: @result.message
				@order.destroy
			end	
		else
		  @client_token = Braintree::ClientToken.generate
		  render :new
		end
	end
	
	def show
	end
	
	def destroy
		@order.destroy
		redirect_to root_url, notice: 'Incripcion Eliminada'
	end
	
	private
	
	def set_order
		@order = Order.find(params[:id])
	end
	
	def order_params
		params.require(:order).permit(:name, :email, :address,:telefono, :city, :country)
	end

	def charge 
		@result = Braintree::Transaction.sale[
 		amount:  @registro.total_precio,
  		payment_method_nonce: params {:payment_method_nonce}]
	end
 end