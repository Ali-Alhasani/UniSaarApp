//
//  MensaViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
class MensaViewController: UIViewController {
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var mensaCollectionView: UICollectionView! {
        didSet {
            DispatchQueue.main.async {
                let refreshControl = self.mensaCollectionView.setUpRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.load), for: UIControl.Event.valueChanged)
                self.mensaCollectionView.refreshControl = refreshControl
            }
        }
    }
    // MARK: - Instance Properties
    lazy var mensaMenuViewModel: MensaMenuViewModel = MensaMenuViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupCollectionView()
        bindViewModel()
        load()
        //just a test mock function without server calling
        //mensaMenuViewModel.loadGetMockMenu()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    // refresh UICollectionView layout after rotation of the device (iPad)
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        mensaCollectionView.collectionViewLayout.invalidateLayout()
    }

    @objc func load() {
        mensaMenuViewModel.loadGetMensaMenu()
    }
    func setupCollectionView() {
        mensaCollectionView.register(MensaCollectionViewCell.nib, forCellWithReuseIdentifier: MensaCollectionViewCell.identifier)
        mensaCollectionView.register(ErrorCellCollectionViewCell.nib, forCellWithReuseIdentifier: ErrorCellCollectionViewCell.identifier)
        mensaCollectionView.delegate = self
        mensaCollectionView.dataSource = self
        pageControl.hidesForSinglePage = true
        mensaCollectionView.layoutCollectionView()
    }
    func bindViewModel() {
        self.mensaCollectionView.showingLoadingView()
        mensaMenuViewModel.daysMenus.bind { [weak self] _ in
            if let `self` = self {
                DispatchQueue.main.async {
                    self.mensaCollectionView.reloadData()
                    let numberOfPages = self.mensaMenuViewModel.daysMenus.value.count
                    self.pageControl.numberOfPages = numberOfPages
                    self.initialSelection()
                }
            }
        }
        mensaMenuViewModel.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        mensaMenuViewModel.showLoadingIndicator.bind { [weak self] visible in
            if let `self` = self {
                visible ? self.mensaCollectionView.showingLoadingView() : self.mensaCollectionView.hideLoadingView()
            }
        }
    }
    // select default item in detail view for iPad in SplitViewController
    func initialSelection() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            DispatchQueue.main.async {
                let initialIndexPath = IndexPath(row: 0, section: 0)
                switch self.mensaMenuViewModel.daysMenus.value[safe: initialIndexPath.row] {
                case .normal(let viewModel):
                    self.performSegue(withIdentifier: SegueIdentifiers.toMealDetails, sender: viewModel.mealsCells[0])
                case .empty, .error, .none:
                    // nop no click action should be done for empty cell's
                    break
                }
            }
        }
    }
    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toMealDetails = "toMealDetails"
        static let toLocationDetails = "toLocationInfo"
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == SegueIdentifiers.toMealDetails,
            let destination = segue.destination as? UINavigationController,
            let destinationViewController = destination.topViewController as? MealDetailsViewController,
            let viewModel = sender as? MensaMealCellViewModel {
            destinationViewController.mealItemViewModel = viewModel
        } else if let destination = segue.destination as? UINavigationController, let destinationViewController = destination.topViewController as? FilterMensaViewController {
            destinationViewController.delegate = self
            destinationViewController.filterMensaViewModel.isFilterdCacheUpdated = mensaMenuViewModel.isFilterdCacheUpdated
        }
    }
}
// MARK: UICollectionViewDelegate&UICollectionViewDataSource
extension MensaViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mensaMenuViewModel.daysMenus.value.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch mensaMenuViewModel.daysMenus.value[safe: indexPath.row] {
        case .normal(let viewModel):
            guard let cell = mensaCollectionView.dequeueReusableCell(withReuseIdentifier: MensaCollectionViewCell.identifier, for: indexPath) as? MensaCollectionViewCell else {
                return UICollectionViewCell()
            }
            cell.dayMenuViewModel = viewModel
            cell.delegate = self
            return cell
        case .error(let message):
            guard let cell = mensaCollectionView.dequeueReusableCell(withReuseIdentifier: ErrorCellCollectionViewCell.identifier, for: indexPath)
                as? ErrorCellCollectionViewCell else {
                    return UICollectionViewCell()
            }
            cell.text = message
            return cell
        case .empty:
            guard let cell = mensaCollectionView.dequeueReusableCell(withReuseIdentifier: ErrorCellCollectionViewCell.identifier, for: indexPath)
                as? ErrorCellCollectionViewCell else {
                    return UICollectionViewCell()
            }
            cell.text = NSLocalizedString("emptyMenu", comment: "no menu")
            return cell
        case .none:
            break
        }
        return UICollectionViewCell()
    }
}
// MARK: MensaCollectionViewCellDelegate
extension MensaViewController: MensaCollectionViewCellDelegate {

    func didTapMealDetails(meal: MensaMealCellViewModel) {
        self.performSegue(withIdentifier: SegueIdentifiers.toMealDetails, sender: meal)
    }
    func didTapLocationDetails() {
        self.performSegue(withIdentifier: SegueIdentifiers.toLocationDetails, sender: self)
    }
}
// MARK: UICollectionViewDelegateFlowLayout
extension MensaViewController: UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height )
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        pageControl.currentPage = currentPage
    }
}

extension MensaViewController: SingleButtonDialogPresenter { }
extension MensaViewController: FilterMensaViewDelegate {
    func didUpdateNoticesData() {
        self.mensaMenuViewModel.isFilterdCacheUpdated = true
    }

    func didUpdateNoticesFilter() {
        DispatchQueue.main.async {
            self.mensaCollectionView.reloadData()
        }
    }
    func didChangeLocationFilter() {
        self.load()
    }
}
