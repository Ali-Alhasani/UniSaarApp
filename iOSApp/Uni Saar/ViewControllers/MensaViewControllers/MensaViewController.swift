//
//  MensaViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/3/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import Observation

@MainActor
class MensaViewController: UIViewController {
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var mensaCollectionView: UICollectionView! {
        didSet {
            let refreshControl = mensaCollectionView.setUpRefreshControl()
            refreshControl.addTarget(self, action: #selector(self.load), for: .valueChanged)
            mensaCollectionView.refreshControl = refreshControl
        }
    }
    lazy var mensaMenuViewModel: MensaMenuViewModel = MensaMenuViewModel()
    private var didLoadInitialContent = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        startObserving()
        load()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isMenuUpdated()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        mensaCollectionView.collectionViewLayout.invalidateLayout()
    }

    @objc func load() {
        Task { [weak self] in await self?.mensaMenuViewModel.loadGetMensaMenu() }
    }

    func setupCollectionView() {
        mensaCollectionView.register(MensaCollectionViewCell.nib, forCellWithReuseIdentifier: MensaCollectionViewCell.identifier)
        mensaCollectionView.register(ErrorCellCollectionViewCell.nib, forCellWithReuseIdentifier: ErrorCellCollectionViewCell.identifier)
        mensaCollectionView.delegate = self
        mensaCollectionView.dataSource = self
        pageControl.hidesForSinglePage = true
        mensaCollectionView.layoutCollectionView()
    }

    private func startObserving() {
        withObservationTracking {
            _ = mensaMenuViewModel.daysMenus
            _ = mensaMenuViewModel.currentAlert
            mensaCollectionView.reloadData()
            pageControl.numberOfPages = mensaMenuViewModel.daysMenus.count
            mensaMenuViewModel.showLoadingIndicator ? mensaCollectionView.showingLoadingView() : mensaCollectionView.hideLoadingView()
            if !didLoadInitialContent && !mensaMenuViewModel.daysMenus.isEmpty {
                didLoadInitialContent = true
                initialSelection()
            }
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let alert = mensaMenuViewModel.currentAlert {
                    mensaMenuViewModel.currentAlert = nil
                    presentSingleButtonDialog(alert: alert)
                }
                startObserving()
            }
        }
    }

    func isMenuUpdated() {
        mensaMenuViewModel.isMenuUpdated()
    }

    func initialSelection() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let initialIndexPath = IndexPath(row: 0, section: 0)
            switch mensaMenuViewModel.daysMenus[safe: initialIndexPath.row] {
            case .normal(let viewModel):
                performSegue(withIdentifier: SegueIdentifiers.toMealDetails, sender: viewModel.mealsCells[0])
            case .empty, .error, .none:
                break
            }
        }
    }

    internal struct SegueIdentifiers {
        static let toMealDetails = "toMealDetails"
        static let toLocationDetails = "toLocationInfo"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toMealDetails,
            let destination = segue.destination as? UINavigationController,
            let destinationViewController = destination.topViewController as? MealDetailsViewController,
            let viewModel = sender as? MensaMealCellViewModel {
            destinationViewController.mealItemViewModel = viewModel
        } else if let destination = segue.destination as? UINavigationController,
                  let destinationViewController = destination.topViewController as? FilterMensaViewController {
            destinationViewController.delegate = self
            destinationViewController.filterMensaViewModel.isFilterdCacheUpdated = mensaMenuViewModel.isFilterdCacheUpdated
        }
    }
}

extension MensaViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mensaMenuViewModel.daysMenus.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch mensaMenuViewModel.daysMenus[safe: indexPath.row] {
        case .normal(let viewModel):
            guard let cell = mensaCollectionView.dequeueReusableCell(withReuseIdentifier: MensaCollectionViewCell.identifier, for: indexPath) as? MensaCollectionViewCell else {
                return UICollectionViewCell()
            }
            cell.dayMenuViewModel = viewModel
            cell.delegate = self
            return cell
        case .error(let message):
            guard let cell = mensaCollectionView.dequeueReusableCell(withReuseIdentifier: ErrorCellCollectionViewCell.identifier, for: indexPath) as? ErrorCellCollectionViewCell else {
                return UICollectionViewCell()
            }
            cell.text = message
            return cell
        case .empty:
            guard let cell = mensaCollectionView.dequeueReusableCell(withReuseIdentifier: ErrorCellCollectionViewCell.identifier, for: indexPath) as? ErrorCellCollectionViewCell else {
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

extension MensaViewController: MensaCollectionViewCellDelegate {
    func didTapMealDetails(meal: MensaMealCellViewModel) {
        performSegue(withIdentifier: SegueIdentifiers.toMealDetails, sender: meal)
    }
    func didTapLocationDetails() {
        performSegue(withIdentifier: SegueIdentifiers.toLocationDetails, sender: self)
    }
}

extension MensaViewController: UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
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
        mensaMenuViewModel.isFilterdCacheUpdated = true
    }
    func didUpdateNoticesFilter() {
        mensaCollectionView.reloadData()
    }
    func didChangeLocationFilter() {
        load()
    }
}
