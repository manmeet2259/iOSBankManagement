//
//  MainViewController.swift
//  IOS-FinalProject-LSBank
//
//  Created by user203175 on 10/19/21.
//

import UIKit

class MainViewController: UIViewController, BalanceRefresh, UITableViewDataSource, UITableViewDelegate{
   
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var refreshControl = UIRefreshControl()
    var recentTransactions : [TransactionsStatementTransaction] = []
    
    @IBOutlet weak var vBtnWithdraw : UIView!
    @IBOutlet weak var vBtnDeposit : UIView!
    @IBOutlet weak var vBtnTransfer : UIView!
    
    @IBOutlet weak var lblUsername : UILabel!
    @IBOutlet weak var lblBalance : UILabel!
    
    @IBOutlet weak var btnRefreshBalance : UIButton!
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var lblRecentTransactions: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initialize()
        
        lblUsername.text = "Hi \(LoginViewController.account!.firstName)"
        
        refreshBalance()
        
        
    }
    
    private func initialize(){
        customizeView()
        
        tableView.register(StatementTableViewCell.nib(), forCellReuseIdentifier: StatementTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.enableTapGestureRecognizer(target: self, action: #selector(tableViewTapped(tapGestureRecognizer:)))

        refreshControl.addTarget(self, action: #selector(tableRefreshControl), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        
    }
    
    @objc func tableViewTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.view.endEditing(true)
    }
    
    @objc func tableRefreshControl(send : UIRefreshControl) {
        
        DispatchQueue.main.async {
            print("Refreshing table")
                        
            self.refreshBalance()
            self.refreshControl.endRefreshing()
        }
        
    }
    private func customizeView() {
        vBtnWithdraw.setLayerCornerRadius(MyAppDefaults.LayerCornerRadius.button)
        vBtnDeposit.setLayerCornerRadius(MyAppDefaults.LayerCornerRadius.button)
        vBtnTransfer.setLayerCornerRadius(MyAppDefaults.LayerCornerRadius.button)
    }
    
    
    @IBAction func btnLogOff(_ sender: Any) {
        
        let btnYes = Dialog.DialogButton(title: "Yes", style: .default, handler: {action in
            self.navigationController?.popViewController(animated: true)
        })
        let btnNo = Dialog.DialogButton(title: "No", style: .destructive, handler: nil)
        
        Dialog.show(view: self, title: "Login off", message: "\(LoginViewController.account!.firstName), are you sure you want to leave?", style: .actionSheet, completion: nil, presentAnimated: true, buttons: btnYes, btnNo)
        
        
    }
    
    
    
    func refreshBalanceSuccess(httpStatusCode : Int, response : [String:Any] ){
        
        DispatchQueue.main.async {
            self.btnRefreshBalance.isEnabled = true
            self.lblBalance.text = "?"
        }
        
        if httpStatusCode == 200 {
            
            if let accountBalance = AccountsBalance.decode(json: response){
                
                DispatchQueue.main.async {
                    self.lblBalance.text = "CAD$ " + accountBalance.balance.formatAsCurrency()
                }
                
            }
        } else {
            DispatchQueue.main.async {
                Toast.show(view: self, title: "Something went wrong!", message: "Error parsing data received from server! Try again!")
            }
        }
        
    }
    
    
    func refreshBalanceFail( httpStatusCode : Int, message : String ){
        
        DispatchQueue.main.async {
            self.lblBalance.text = ""
            self.btnRefreshBalance.isEnabled = true
            Toast.show(view: self, title: "Ooops!", message: message)
        }
        
    }
    
    
    
    func refreshBalance() {
        
        lblBalance.text = "wait..."
      
        LSBankAPI.accountBalance(token: LoginViewController.token, successHandler: refreshBalanceSuccess, failHandler: refreshBalanceFail)
        
        refreshRecentTransactions()
       
    }
    
    func refreshRecentTransactions(){
        
        LSBankAPI.statement(token: LoginViewController.token, days: 30, successHandler: refreshRecentTransactionsSuccess, failHandler: refreshRecentTransactionsFail)
        
               
    }
    
    func refreshRecentTransactionsFail( httpStatusCode : Int, message : String ){
        
        DispatchQueue.main.async {
                Toast.show(view: self, title: "Ooops!", message: message)
        }
        
    }
    
    func refreshRecentTransactionsSuccess(httpStatusCode : Int, response : [String:Any] ){
        
        DispatchQueue.main.async {
        }
        
        if httpStatusCode == 200 {
            
            if let transactions = TransactionStatement.decode(json: response){
                
                DispatchQueue.main.async {
                    self.recentTransactions = transactions.statement
                    
                    self.tableView.reloadData()
                }
                
                      
            }
        } else {
            DispatchQueue.main.async {
                Toast.show(view: self, title: "Something went wrong!", message: "Error parsing data received from server! Try again!")
            }
        }
        
    }
    
    @IBAction func btnRefreshBalanceTouchUp(_ sender : Any? ) {
        
        btnRefreshBalance.isEnabled = false
        refreshBalance()
        
    }
    
    @IBAction func btnPayeeTouchUp(_ sender : Any? ) {
        
        performSegue(withIdentifier: Segue.toPayeesView, sender: nil)
        
    }
    
    @IBAction func btnSendMoneyTouchUp(_ sender : Any? ){
        
        if Payee.all(context: self.context).count == 0 {
            Toast.ok(view: self, title: "No payees", message: "Please, set your payees list before sending money!")
            return
        }
        
        
        performSegue(withIdentifier: Segue.toSendMoneyView, sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segue.toSendMoneyView {
            
            (segue.destination as! SendMoneyViewController).payeeList = Payee.allByFirstName(context: self.context)
            (segue.destination as! SendMoneyViewController).delegate = self
            
            
        }
        
    }
    
    func balanceRefresh() {
        // BalanceRefresh protocol stub
        self.refreshBalance()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.recentTransactions.count == 0
            {
            lblRecentTransactions.text = "No recent transactions"
            }
        else {
            if self.recentTransactions.count == 1 {
                lblRecentTransactions.text = "1 recent transactions"
            }
            else {
                lblRecentTransactions.text = "\(self.recentTransactions.count) recent transactions"
                }
    
        }
        
        return self.recentTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: StatementTableViewCell.identifier, for: indexPath) as! StatementTableViewCell
        
        let transaction = self.recentTransactions[self.recentTransactions.count - 1 - indexPath.row]
        
        var accountHolderName : String = ""
        var credit : Bool = true
        
        if
            LoginViewController.account!.accountId.contains(transaction.fromAccount!.accountId){
            credit = false
            accountHolderName = "\(transaction.toAccount!.firstName.uppercased()) \(transaction.toAccount!.lastName.uppercased())."
        }
        else{
            credit = true
            accountHolderName = "\(transaction.fromAccount!.firstName.uppercased()) \(transaction.fromAccount!.lastName.uppercased())."
        }
        
        cell.setCellContent(dateTime: transaction.dateTime, accountHolder: accountHolderName, amount: transaction.amount, credit: credit, message: transaction.message)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let transaction = self.recentTransactions[self.recentTransactions.count - 1 - indexPath.row]
        
        if transaction.message.count == 0 {
            
            return 100   // no message
        }
        
        return 138
    }

}
