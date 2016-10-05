//
//  RuleSetListViewController.swift
//  Potatso
//
//  Created by LEI on 5/31/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoModel
import Cartography
import Realm
import RealmSwift

private let rowHeight: CGFloat = 54
private let kRuleSetCellIdentifier = "ruleset"

class RuleSetListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var ruleSets: Results<RuleSet>
    var chooseCallback: ((RuleSet?) -> Void)?
    // Observe Realm Notifications
    var token: RLMNotificationToken?
    var heightAtIndex: [Int: CGFloat] = [:]

    init(chooseCallback: ((RuleSet?) -> Void)? = nil) {
        self.chooseCallback = chooseCallback
        self.ruleSets = DBUtils.allNotDeleted(RuleSet.self, sorted: "createAt")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Rule Set".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        reloadData()
        token = ruleSets.addNotificationBlock { [unowned self] (changed) in
            switch changed {
            case let .Update(_, deletions: deletions, insertions: insertions, modifications: modifications):
                self.tableView.beginUpdates()
                defer {
                    self.tableView.endUpdates()
                }
                self.tableView.deleteRowsAtIndexPaths(deletions.map({ NSIndexPath(forRow: $0, inSection: 0) }), withRowAnimation: .Automatic)
                self.tableView.insertRowsAtIndexPaths(insertions.map({ NSIndexPath(forRow: $0, inSection: 0) }), withRowAnimation: .Automatic)
                self.tableView.reloadRowsAtIndexPaths(modifications.map({ NSIndexPath(forRow: $0, inSection: 0) }), withRowAnimation: .None)
            case let .Error(error):
                error.log("RuleSetListVC realm token update error")
            default:
                break
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        token?.stop()
    }

    func reloadData() {
        ruleSets = DBUtils.allNotDeleted(RuleSet.self, sorted: "createAt")
        tableView.reloadData()
    }

    func add() {
        let vc = RuleSetConfigurationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    func showRuleSetConfiguration(_ ruleSet: RuleSet?) {
        let vc = RuleSetConfigurationViewController(ruleSet: ruleSet)
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ruleSets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kRuleSetCellIdentifier, for: indexPath) as! RuleSetCell
        cell.setRuleSet(ruleSets[indexPath.row], showSubscribe: true)
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        heightAtIndex[(indexPath as NSIndexPath).row] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let ruleSet = ruleSets[indexPath.row]
        if let cb = chooseCallback {
            cb(ruleSet)
            close()
        }else {
            showRuleSetConfiguration(ruleSet)
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = heightAtIndex[(indexPath as NSIndexPath).row] {
            return height
        } else {
            return UITableViewAutomaticDimension
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return chooseCallback == nil
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item: RuleSet
            guard indexPath.row < ruleSets.count else {
                return
            }
            item = ruleSets[indexPath.row]
            do {
                try DBUtils.softDelete(item.uuid, type: RuleSet.self)
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
    }
    

    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.clear
        view.addSubview(tableView)
        tableView.register(RuleSetCell.self, forCellReuseIdentifier: kRuleSetCellIdentifier)

        constrain(tableView, view) { tableView, view in
            tableView.edges == view.edges
        }
    }

    lazy var tableView: UITableView = {
        let v = UITableView(frame: CGRect.zero, style: .plain)
        v.dataSource = self
        v.delegate = self
        v.tableFooterView = UIView()
        v.tableHeaderView = UIView()
        v.separatorStyle = .singleLine
        v.rowHeight = UITableViewAutomaticDimension
        return v
    }()

}
