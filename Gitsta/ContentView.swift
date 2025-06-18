//
//  ContentView.swift
//  Gitsta
//
//  Created by Chaira Harder on 6/17/25.
//

/* Network call implementation using Git's REST API */

import SwiftUI
// v2
import Combine

struct ContentView: View {
    
    // v1
    @State private var user: GitHubUser?
    
    // v2
    @State private var searchText = ""
    
    @State private var searchCancellable: AnyCancellable?
    
    let taglines = ["straight outta", "emerging from some basement in", "hacking away at some keys from", "if not in Bali right now, i'm in", "coming atcha from"]
    
    @State private var selectedTagline = "straight outta"
    
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text(selectedTagline)
                .padding(.top, 40)
                .foregroundStyle(.gray)
            
            Text(user?.location ?? "guess you have no home")
//                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .fontWeight(.semibold)
                .foregroundStyle(.gray)
            
            Text("with \(user?.publicRepos ?? 0) public repos")
                .multilineTextAlignment(.center)
//                .fontWeight(.semibold)
                .foregroundStyle(.green)
            
            // user profile picture
            AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .foregroundStyle(.secondary)
            }
                .frame(width: 120, height: 120)
                .padding(.top, 20)
            
            // username
            Text(user?.login ?? "if u were logged in the username would be here")
                .bold()
                .font(.title3)
            
            // user biography
            Text(user?.bio ?? "and if u were logged in the bio would be here too")
                .padding()
            
            
            // search bar
            TextField("look some githuber up", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onChange(of: searchText) { _, newValue in
                    // cancel previous search if still running
                    searchCancellable?.cancel()
                    
                    // debounce typing to reduce API spam
                    searchCancellable = Just(newValue)
                        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                        .removeDuplicates() // v3 debugging automatic search
                        .sink { username in
                            Task {
                                guard !username.isEmpty else {
                                    user = nil
                                    return
                                }
                                do {
                                    self.user = try await getUser(username: username)
                                    self.selectedTagline = taglines.randomElement() ?? "right from"
                                } catch {
                                    print("error fetching: \(error)")
                                    user = nil
                                }
                            }
                        }
                }
            
            // search button
            // TODO: automatic continuous search not working properly
            Button("searchhh"){
                Task {
                    do {
                        user = try await getUser(username: searchText)
                        self.selectedTagline = taglines.randomElement() ?? "from the void of"
                    } catch {
                        print("Error fetching user: \(error)")
                        self.user = nil
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
            
            Spacer()
        }
        .padding()
        .task {
            do {
                user = try await getUser(username: "cyberchai") // default
            } catch GHError.invalidURL {
                print("Invalid URL")
            } catch GHError.invalidResponse {
                print("Invalid Response")
            } catch GHError.invalidData {
                print("Invalid Data")
            } catch {
                print("Unexpected error")
            }
        }
        
        
        
        
    }
    

    func getUser(username: String) async throws -> GitHubUser {
        let endpoint = "https://api.github.com/users/\(username)"
        
        guard let url = URL(string: endpoint) else {
            throw GHError.invalidURL
        } 
        
        // GET request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GHError.invalidResponse
        }
        // TODO: make error messages more specific
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(GitHubUser.self, from: data)
        }catch {
            throw GHError.invalidData
        }
        
    }
    
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct GitHubUser: Codable {
    let login: String
    let avatarUrl: String
    let bio: String
    
    let location: String
    let blog: String
    let publicRepos: Int
}


enum GHError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
