//
//  MensaCollectionViewCell.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

protocol MensaCollectionViewCellDelegate: class {
    func didTapMealDetails(meal: MensaMealCellViewModel)
    func didTapLocationDetails()
}
class MensaCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var mensaTable: UITableView!

    var dayMenuViewModel: MensaDayMenuViewModel? {
        didSet {
            DispatchQueue.main.async {
                self.mensaTable.reloadData()
            }
        }
    }
    weak var delegate: MensaCollectionViewCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupTableView()
    }
    func setupTableView() {
        mensaTable.register(MensaMenuTableViewCell.nib, forCellReuseIdentifier: MensaMenuTableViewCell.identifier)
        mensaTable.register(MensaDateHeaderSectionTableViewCell.nib, forHeaderFooterViewReuseIdentifier: MensaDateHeaderSectionTableViewCell.identifier)
        mensaTable.delegate = self
        mensaTable.dataSource = self
        mensaTable.layoutTableView()
    }
}

extension MensaCollectionViewCell: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayMenuViewModel?.mealsCells.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let viewModel =  dayMenuViewModel?.mealsCells[safe: indexPath.row] {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MensaMenuTableViewCell.identifier, for: indexPath) as? MensaMenuTableViewCell else {
                return UITableViewCell()
            }
            viewModel.configure(cell)
            cell.selectionStyle = .none
            return cell
        }
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: MensaDateHeaderSectionTableViewCell.identifier) as? MensaDateHeaderSectionTableViewCell else {
            return nil
        }
        cell.dayMenuViewModel = dayMenuViewModel
        return cell
    }
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let viewModel =  dayMenuViewModel?.mealsCells[safe: indexPath.row] {
            self.delegate?.didTapMealDetails(meal: viewModel)
        }
    }
}
