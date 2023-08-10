# 📝 할일목록 앱
# 📜 프로젝트 소개
>진행 기간: 2023.05.08 ~ 2023.06.20
>
개발하는 정대리 Todo api를 이용한 할일목록 앱 개발 프로젝트입니다

# 🛠 기술 스택
<img src="https://img.shields.io/badge/Swift-white?style=flat&logo=Swift&logoColor=F05138"> 

# 🖥 프로젝트 특징
- 메인 화면에 들어가면 개발하는 정대리 Todo API를 이용해서 저장된 할일목록들을 불러옵니다.
- 화면에서 할일 목록 중에 하나를 누르면 해당 할일 목록을 수정하거나 삭제할 수 있습니다
- +버튼을 누르면 할일 목록 추가가 가능합니다
- 검색 창에서 할일 목록을 검색할 수 있습니다

# ✨ 성장 경험
### MVVM패턴

기존에도 할일목록 앱을 만들었지만 비지니스로직과 화면에 관련된 부분이 모두 한 클래스에 모여있는 MVC패턴을 이용해서 개발을 진행했었습니다. 하지만 비지니스 로직이 분리되어있지 않다보니 비슷한 로직을 여러번 작성해야 하는 상황이 생겼고 이런 부분을 어떻게 하면 줄일 수 있을까 찾아보던 중에 자연스럽게 MVVM패턴에 대해서 관심이 생기게 되어 MVVM패턴에 대해서 공부하게 되었고 이 패턴을 적용한 앱을 만들면서 MVVM패턴에 대해서 익힐 수 있었습니다

### Rxswift

비동기 처리는 클로저를 이용해서 대부분 처리를 하였는데 그러다보니까 로직도 복잡해지고 유지보수도 힘들 것 같다는 생각이 들었고 다른 비동기 처리에 대한 관심이 생기면서 rx를 알게되었고 rx에 대해서 조금 더 알아보기 위해서 프로젝트를 진행하게 되었습니다

### 앱관련 기타 문서
[개발일지](https://ramudev.oopy.io/3f024919-251b-4a55-bdab-456efb528a37)

# 👀서비스 화면
<img src="https://github.com/Kimrayoung/ios_TodoList_RxMVVM/assets/66238470/7eca7e61-f582-4dc1-960b-5711842f7b25" width="200px" height="400px">        <img src="https://github.com/Kimrayoung/ios_TodoList_RxMVVM/assets/66238470/f0acea1d-4ce2-431c-9eb1-7542ad6bcf68" width="200px" heigth="400px">
