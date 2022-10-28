//
//  HomeTableViewController.swift
//  MarvelLoader
//
//  Created by Luka Lešić on 05.10.2022..
//

import UIKit

class ComicTableViewController: UIViewController, ViewModelDelegate {
        
    var tableView = UITableView(frame: CGRect(), style: .insetGrouped)
    private var comicsViewModel = ComicsViewModel()
    
    private lazy var dataSource = makeDataSource()
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Comic>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Comic>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Marvel Loader"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.red]
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        tableView.dataSource = dataSource
        
        //izbaciti task  odavdje i async iz funkcije
        Task{
            do {
                try await comicsViewModel.loadData(completion: { success in
                    DispatchQueue.main.async {
                        self.applySnapshot(animatingDifferences: true)
                    }
                })
                
            }
            catch{ print("error") }
        }
            configureTableView()
}
    
    //mainactor
    func applySnapshot(animatingDifferences: Bool = true) {
        //vm
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(comicsViewModel.comicbooks!, toSection: .main)
      dataSource.apply(snapshot, animatingDifferences: true)
        print("snapshot applied")
    }
    
    func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, _  in
                
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: Cells.comicCell,
                    for: indexPath) as? ComicCell
                                
                let cellViewModel = self.comicsViewModel.comicCellViewModel(at: indexPath)
                cell!.updateWith(viewModel: cellViewModel)
                
                return cell
            })
    }

    func configureTableView() {
        view.addSubview(tableView)
        tableView.configureForAutoLayout()
        tableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        
       setTableViewDelegates()
        tableView.register(ComicCell.self, forCellReuseIdentifier: Cells.comicCell)
    }
    
    func setTableViewDelegates(){
        comicsViewModel.delegate = self
        tableView.delegate = self
    }
}

extension ComicTableViewController {
    enum Section: Hashable {
      case main
    }
    
    func reloadTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            //tu moze snapshot
        }
    }
}

extension ComicTableViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
       guard let comic = dataSource.itemIdentifier(for: indexPath) else {
          return
        }
       
        let detailVM = DetailViewModel(comic: comic)
        let detailView = DetailViewController(viewModel: detailVM)
        navigationController?.pushViewController(detailView, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}



