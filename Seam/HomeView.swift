import SwiftUI

// MARK: - Model
struct ClothingItem {
    var type: String
    var addOn: String
    var color: Color
}

struct HomeView: View {
    
    let modes = ["Add", "Closet", "Outfits"]
    @State private var selectedMode = "Add"
    var body: some View{
        VStack (spacing: 20){
            HStack(spacing: 20){
                Text("Seam")
                    .font(.title)
                    .padding(10)
                Spacer()
            }
            
            NavigationLink(destination: AddView()) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
            
            
            Spacer()
            
        }
    }
}


#Preview {
    HomeView();
}
