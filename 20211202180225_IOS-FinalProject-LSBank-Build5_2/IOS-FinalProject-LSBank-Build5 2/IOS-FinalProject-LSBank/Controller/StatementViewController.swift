//
//  StatementViewController.swift
//  IOS-FinalProject-LSBank
//
//  Created by Syed Samiuddin on 2021-12-02.
//

import UIKit

class StatementViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    
    
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var refreshControl = UIRefreshControl()
    var recentTransactions : [TransactionsStatementTransaction] = []
    var days : Int = 30
    
    @IBOutlet weak var section: UISegmentedControl!
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            
            days = 30
            self.refreshRecentTransactions(days: days)
        }
        if sender.selectedSegmentIndex == 1 {
         
            days = 60
            self.refreshRecentTransactions(days: days)
        }
        if sender.selectedSegmentIndex == 2 {
            
            days = 120
            self.refreshRecentTransactions(days: days)
        }
    }
    
    private func initialize(){
        
        
        tableView.register(StatementTableViewCell.nib(), forCellReuseIdentifier: StatementTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.enableTapGestureRecognizer(target: self, action: #selector(tableViewTapped(tapGestureRecognizer:)))

        refreshControl.addTarget(self, action: #selector(tableRefreshControl), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        
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
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func btnClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @objc func tableViewTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.view.endEditing(true)
    }
    
    @objc func tableRefreshControl(send : UIRefreshControl) {
        
        DispatchQueue.main.async {
            print("Refreshing table")
            self.refreshRecentTransactions(days: self.days)
            self.refreshControl.endRefreshing()
        }
        
    }
    
    func refreshRecentTransactions(days : Int){
        
        LSBankAPI.statement(token: LoginViewController.token, days: days, successHandler: refreshRecentTransactionsSuccess, failHandler: refreshRecentTransactionsFail)
        
               
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         do {
            
            let transaction = self.recentTransactions[self.recentTransactions.count - 1 - indexPath.row]
            
            if transaction.message.count == 0 {
                
                return 100   // no message
            }
            
            return 138
         }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        section.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        refreshRecentTransactions(days: days)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
