---
name: ue-angelscript
description: Guide for developing games with Unreal Engine Angelscript - a scripting language plugin for UE5 that enables rapid iteration and improved cooperation between programmers and designers. Use when writing Angelscript code for UE5 gameplay systems, actors, components, UI, networking, editor extensions, or C++ binding.
license: MIT
metadata:
  author: AI Assistant
  version: "1.1"
  tags: ["unreal-engine", "angelscript", "game-development", "ue5", "scripting", "cpp-binding"]
---

# UE-Angelscript Development Guide

Unreal Engine Angelscript (UE-AS) is a full-featured scripting language plugin for UE5 developed by Hazelight (creators of *It Takes Two* and *Split Fiction*). It combines the rapid iteration of scripting with performance approaching native C++.

## Overview

### Key Benefits

- **Rapid Iteration**: Scripts reload instantly in editor without recompiling or restarting
- **Improved Cooperation**: Programmers and designers work with the same systems and tools
- **Performance**: Significantly faster than Blueprint; approaches C++ with transpiled scripts in shipping builds
- **Familiar Syntax**: C++-like syntax that's easy to learn for developers familiar with Unreal

### When to Use Angelscript vs Blueprint vs C++

| Use Case | Recommended |
|----------|-------------|
| Rapid prototyping | Angelscript |
| Complex gameplay systems | Angelscript |
| Designer-accessible logic | Angelscript or Blueprint |
| Performance-critical code | C++ or transpiled Angelscript |
| Editor tools and automation | Angelscript |
| UI logic | Angelscript |
| Quick visual scripting | Blueprint |
| Binding C++ to AS | C++ |

## Installation & Setup

### Prerequisites

- Unreal Engine 5.x (5.2+ recommended)
- Git
- Visual Studio Code (recommended)

### Installing the Plugin

1. **Clone the repository** into your project's `Plugins` folder:
   ```bash
   cd YourProject/Plugins
   git clone https://github.com/Hazelight/UnrealEngine-Angelscript.git Angelscript
   ```

2. **Enable the plugin** in your `.uproject` file:
   ```json
   {
     "Plugins": [
       {
         "Name": "Angelscript",
         "Enabled": true
       }
     ]
   }
   ```

3. **Regenerate project files** and rebuild

4. **Verify installation**: Check `Window > Angelscript` menu in editor

### VSCode Setup (Recommended)

Install these extensions for the best development experience:
- **Unreal Angelscript** - Syntax highlighting, autocomplete, debugging
- **Unreal Angelscript Clang-Format** - Code formatting

Key features:
- Set breakpoints directly in VSCode
- Auto-completion for all bound types
- Real-time error detection
- Go to definition

### Project Structure

```
YourProject/
├── Content/
│   └── Script/              # Angelscript source files
│       ├── MyActor.as
│       ├── Components/
│       ├── UI/
│       ├── Gameplay/
│       └── Editor/          # Editor-only scripts (#if EDITOR)
├── Plugins/
│   └── Angelscript/
└── YourProject.uproject
```

## Core Concepts

### Basic Script Structure

```angelscript
// MyActor.as - An Angelscript actor class
class AMyActor : AActor
{
    UPROPERTY()
    float Health = 100.0f;
    
    UPROPERTY()
    float Speed = 500.0f;
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        Print("Actor spawned! Health: " + Health);
    }
    
    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        Super::Tick(DeltaTime);
        // Tick logic here
    }
    
    UFUNCTION()
    void TakeDamage(float DamageAmount)
    {
        Health -= DamageAmount;
        if (Health <= 0)
        {
            Destroy();
        }
    }
}
```

### Key Differences from C++

| Feature | C++ | Angelscript |
|---------|-----|-------------|
| Header files | Required (.h) | Not needed |
| Pointers/References | `AActor*`, `FVector&` | `AActor`, `FVector` (automatic) |
| UPROPERTY/UFUNCTION | Macros | Keywords |
| Compilation | Long compile times | Instant hot-reload |
| Memory management | Manual (smart pointers) | Garbage collected |
| nullptr check | Manual | Automatic (optional) |
| Super call | `Super::Function()` | `Super::Function()` |

### Type System

```angelscript
// Primitive types
int32 MyInt = 42;
float MyFloat = 3.14f;
bool MyBool = true;
FString MyString = "Hello World";
FName MyName = n"PlayerName";  // FName literal with 'n' prefix

// Unreal types
FVector Location = FVector(100, 200, 300);
FRotator Rotation = FRotator(0, 90, 0);
FTransform Transform = FTransform(Rotation, Location);

// Object references (no pointers needed!)
AActor OtherActor;
UStaticMeshComponent MeshComponent;

// Arrays and maps
TArray<int32> Scores;
TMap<FString, int32> PlayerScores;
```

### Value Types vs Reference Types

**Value Types** (copied on assignment):
- All primitive types (int, float, bool)
- UStruct types (FVector, FRotator, FTransform, FString, FName, FText)
- Enums

**Reference Types** (Handle - shared reference):
- UObject and all subclasses (AActor, UActorComponent, etc.)
- In AS: `UObject` is equivalent to C++ `UObject*`
- `TArray<UObject>` in AS = `TArray<UObject*>` in C++

**Important**: Struct parameters in functions are automatically passed as `const &` for performance:
```angelscript
// These are equivalent - no copy happens:
void ProcessVector(FVector Vec)           // Actually: const FVector&
void ProcessVector(const FVector Vec)     // Actually: const FVector&
void ProcessVector(const FVector& Vec)    // Explicit const reference
void ProcessVector(FVector& Vec)          // Mutable reference - CAN modify
```

### FName Literals

Use `n"NameLiteral"` syntax for compile-time FName initialization:

```angelscript
FName NameVariable = n"MyName";

// Binding delegates
FExampleDelegate Delegate;
Delegate.BindUFunction(this, n"FunctionBoundToDelegate");

// Gameplay Tags
FGameplayTag Tag = GameplayTags::UI_Action_Escape;
```

### Formatted Strings

Angelscript supports Python-like f-strings:

```angelscript
// Basic formatting
Print(f"Actor: {GetName()} at {ActorLocation}");

// Debug output with =
Print(f"{DeltaSeconds =}");  // Prints: DeltaSeconds = 0.01

// Format specifiers
Print(f"Position: {ActorLocation.Z :.3}");        // 3 decimal places
Print(f"Hex: {20 :#x}");                          // 0x14
Print(f"Binary: {1574 :b}");                      // 11000100110
Print(f"Aligned: {GetName() :>40}");              // Right align to 40 chars
Print(f"Enum name: {ESlateVisibility::Collapsed :n}");  // Just "Collapsed"
```

## Functions and Events

### Function Declaration

```angelscript
// Regular function - automatically BlueprintCallable
UFUNCTION()
float CalculateDamage(float BaseDamage, float Multiplier)
{
    return BaseDamage * Multiplier;
}

// Blueprint pure function (no side effects)
UFUNCTION(BlueprintPure)
bool IsAlive() const
{
    return Health > 0;
}

// Blueprint event - can be overridden in Blueprints
UFUNCTION(BlueprintEvent)
void OnDeath();

// Blueprint override - implementing existing event
UFUNCTION(BlueprintOverride)
void BeginPlay()
{
    Super::BeginPlay();
    // Implementation
}
```

### Blueprint Event Best Practices

```angelscript
class AExamplePickupActor : AActor
{
    // Main logic - always runs
    void PickedUp()
    {
        Print(f"Pickup {this} was picked up!");
        SetActorHiddenInGame(false);
        
        // Call separate blueprint event for extension
        BP_PickedUp();
    }
    
    // Blueprint extension point - no implementation
    UFUNCTION(BlueprintEvent, DisplayName = "Picked Up")
    void BP_PickedUp() {}
}
```

### Calling Super Functions

```angelscript
// Overriding AS method without BlueprintEvent
void PlainMethod(FVector Location) override
{
    Super::PlainMethod(Location);
    // Child implementation
}

// Overriding AS method with BlueprintEvent
UFUNCTION(BlueprintOverride)
void BlueprintEventMethod(int Value)
{
    Super::BlueprintEventMethod(Value);
    // Child implementation
}

// Note: For C++ BlueprintNativeEvent, Super:: may not work due to technical limitations
```

## Properties and Accessors

### Property Declaration

```angelscript
class AMyActor : AActor
{
    // Default: EditAnywhere, BlueprintReadWrite (different from C++)
    UPROPERTY()
    float Score = 0;
    
    // Blueprint read-only
    UPROPERTY(BlueprintReadOnly)
    float MaxHealth = 100.0f;
    
    // Edit defaults only
    UPROPERTY(EditDefaultsOnly)
    float DamageMultiplier = 1.0f;
    
    // Edit instance only
    UPROPERTY(EditInstanceOnly)
    FString InstanceName;
    
    // Visible anywhere (not editable)
    UPROPERTY(VisibleAnywhere)
    UStaticMeshComponent Mesh;
    
    // Not editable at all
    UPROPERTY(NotEditable)
    TArray<int> HiddenArray;
    
    // Category for organization
    UPROPERTY(Category = "Combat")
    float AttackPower = 10.0f;
    
    // Nested categories
    UPROPERTY(Category = "Combat|Advanced")
    float CritChance = 0.05f;
    
    // Meta specifiers
    UPROPERTY(EditAnywhere, meta = (ClampMin = "0", ClampMax = "100"))
    int32 AmmoCount = 30;
}
```

### Property Accessor Functions

Methods starting with `Get...()` or `Set...()` can be used as properties:

```angelscript
class AExampleActor : AActor
{
    // Declare as property accessor
    FVector GetRotatedOffset() const property
    {
        return ActorRotation.RotateVector(FVector(0.0, 1.0, 1.0));
    }
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Use as property - calls GetRotatedOffset()
        Print("Offset: " + RotatedOffset);
    }
}

// C++ bindings: GetActorLocation() can be accessed as ActorLocation
// Actor.ActorLocation is equivalent to Actor.GetActorLocation()
```

**Note**: You can disable automatic property accessors in Project Settings if preferred.

### Access Modifiers

```angelscript
class AExampleActor : AActor
{
    private FVector Offset;           // Only this class
    protected bool bIsMoving = false; // This class and children
    
    UPROPERTY()
    public float PublicValue = 0;     // Everyone (default)
    
    protected void ToggleMoving()
    {
        bIsMoving = !bIsMoving;
    }
}
```

## Actors and Components

### Creating an Actor with Default Components

```angelscript
class AMyPawn : APawn
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    USpringArmComponent CameraBoom;
    
    UPROPERTY(DefaultComponent, Attach = CameraBoom)
    UCameraComponent FollowCamera;
    
    // Default property values using 'default' keyword
    default CameraBoom.TargetArmLength = 400.0f;
    default CameraBoom.bUsePawnControlRotation = true;
    default Camera.bUsePawnControlRotation = false;
    default Mesh.bHiddenInGame = false;
}
```

### Component Attachment Options

```angelscript
class AMyCharacter : ACharacter
{
    // Root component
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;
    
    // Attached to root by default
    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent CharacterMesh;
    
    // Attached to specific component with socket
    UPROPERTY(DefaultComponent, Attach = CharacterMesh, AttachSocket = "RightHand")
    UStaticMeshComponent WeaponMesh;
    
    // Override parent component (must be compatible type)
    UPROPERTY(OverrideComponent = CharMoveComp)
    UMyCharacterMovementComponent MyCharMove;
}
```

### Working with Components

```angelscript
// Get component (returns nullptr if not found)
USkeletalMeshComponent SkelComp = USkeletalMeshComponent::Get(Actor);
USkeletalMeshComponent NamedComp = USkeletalMeshComponent::Get(Actor, n"WeaponMesh");

// Get or create component
UInteractionComponent InteractComp = UInteractionComponent::GetOrCreate(Actor);

// Create new component
UStaticMeshComponent NewComp = UStaticMeshComponent::Create(Character);
NewComp.AttachToComponent(Character.Mesh);

// Get all components of a type
TArray<UStaticMeshComponent> MeshComponents;
Actor.GetComponentsByClass(MeshComponents);
```

### Spawning Actors

```angelscript
// Spawn specific class
AExampleActor Spawned = AExampleActor::Spawn(Location, Rotation);

// Spawn from TSubclassOf
class AExampleSpawner : AActor
{
    UPROPERTY()
    TSubclassOf<AExampleActor> ActorClass;
    
    UFUNCTION()
    void Spawn()
    {
        AExampleActor Spawned = Cast<AExampleActor>(
            SpawnActor(ActorClass, Location, Rotation)
        );
    }
}

// With spawn parameters
FActorSpawnParameters Params;
Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
AProjectile Projectile = Cast<AProjectile>(
    SpawnActor(AProjectile::StaticClass(), Location, Rotation, Params)
);
```

### Construction Script

```angelscript
class AExampleActor : AActor
{
    UPROPERTY()
    int SpawnMeshCount = 5;
    
    UPROPERTY()
    UStaticMesh MeshAsset;
    
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        for (int i = 0; i < SpawnMeshCount; ++i)
        {
            UStaticMeshComponent MeshComp = UStaticMeshComponent::Create(this);
            MeshComp.SetStaticMesh(MeshAsset);
        }
    }
}
```

## Structs and References

### Struct Usage

```angelscript
// Using Unreal structs
FVector Position = FVector(100, 200, 300);
FVector Direction = FVector::ForwardVector;
FVector Normalized = Direction.GetSafeNormal();

float Distance = FVector::Distance(Position, OtherPosition);
FVector ToTarget = (TargetLocation - CurrentLocation).GetSafeNormal();

// Struct modification via reference
void ModifyVector(FVector& Vector)
{
    Vector.X += 10;
    Vector.Y += 20;
}

// Out parameters for Blueprint
UFUNCTION()
void GetRandomPosition(FVector&out OutPosition, bool&out bSuccess)
{
    OutPosition = FVector(Math::RandRange(-100, 100), 0, 0);
    bSuccess = true;
}
```

### Custom Structs

```angelscript
struct FExampleStruct
{
    UPROPERTY()
    float ExampleNumber = 4.0;
    
    UPROPERTY()
    FString ExampleString = "Example String";
    
    // Without UPROPERTY - not visible to Blueprint
    float HiddenNumber = 3.0;
};

// Usage
FExampleStruct CreateStruct(float Number)
{
    FExampleStruct Result;
    Result.ExampleNumber = Number;
    Result.ExampleString = f"{Number}";
    return Result;
}
```

**Note**: Structs in AS cannot have UFUNCTION members. Use Mixin methods to add functionality.

## Delegates and Events

### Declaring Delegates

```angelscript
// Single-cast delegate (can have return value)
delegate float FOnHealthChanged(float NewHealth, float MaxHealth);

// Multicast event (no return value)
event void FOnPlayerDied(AActor Killer);

class AMyCharacter : ACharacter
{
    // Delegate instance
    FOnHealthChanged OnHealthChanged;
    
    // Multicast event
    FOnPlayerDied OnPlayerDied;
    
    UPROPERTY()  // Exposes to Blueprint as Event Dispatcher
    FOnPlayerDied OnPlayerDiedBP;
    
    UFUNCTION()
    void TakeDamage(float Damage)
    {
        Health -= Damage;
        
        // Broadcast to all listeners
        OnHealthChanged.Broadcast(Health, MaxHealth);
        OnPlayerDied.Broadcast(nullptr);
    }
}
```

### Binding to Delegates

```angelscript
class AGameMode : AGameModeBase
{
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        
        AMyCharacter Player = Cast<AMyCharacter>(GetPlayerCharacter());
        if (Player != nullptr)
        {
            // Single-cast: BindUFunction
            Player.OnHealthChanged.BindUFunction(this, n"HandleHealthChanged");
            
            // Multicast: AddUFunction
            Player.OnPlayerDied.AddUFunction(this, n"HandlePlayerDied");
        }
    }
    
    UFUNCTION()
    void HandleHealthChanged(float NewHealth, float MaxHealth)
    {
        Print("Health changed: " + NewHealth + "/" + MaxHealth);
    }
    
    UFUNCTION()
    void HandlePlayerDied(AActor Killer)
    {
        Print("Player died!");
    }
}
```

**VSCode Tip**: Use Ctrl+. (lightbulb) to auto-generate delegate handler functions.

## Mixin Methods

Mixin methods allow adding functionality to existing classes:

```angelscript
// Mixin for AActor
mixin void ExampleMixinTeleportActor(AActor Self, FVector Location)
{
    Self.ActorLocation = Location;
}

// Usage
AActor Actor;
Actor.ExampleMixinTeleportActor(FVector(0, 0, 100));

// Mixin for struct (use & to modify)
mixin void SetVectorToZero(FVector& Vector)
{
    Vector = FVector(0, 0, 0);
}

// Usage
FVector LocalValue;
LocalValue.SetVectorToZero();
```

## Networking

### Networked Properties

```angelscript
class AMyCharacter : ACharacter
{
    // Enable replication for this actor
    default bReplicates = true;
    
    // Replicated property
    UPROPERTY(Replicated)
    float Health = 100.0f;
    
    // Replicated with callback
    UPROPERTY(Replicated, ReplicatedUsing = OnRep_Score)
    int32 Score = 0;
    
    // Owner-only replication
    UPROPERTY(Replicated, ReplicationCondition = OwnerOnly)
    FString PrivateInfo;
    
    UFUNCTION()
    void OnRep_Score()
    {
        Print("Score updated: " + Score);
    }
}
```

### Replication Conditions

- `None` - Always replicate
- `InitialOnly` - Only on initial replication
- `OwnerOnly` - Only to owning client
- `SkipOwner` - To everyone except owner
- `SimulatedOnly` - Only to simulated proxies
- `AutonomousOnly` - Only to autonomous proxies

### RPC Functions

```angelscript
class AMyWeapon : AActor
{
    // Server RPC (client -> server) - Reliable by default
    UFUNCTION(Server, Reliable)
    void Server_Fire(FVector TargetLocation)
    {
        PerformFire(TargetLocation);
    }
    
    // Unreliable Server RPC
    UFUNCTION(Server, Unreliable)
    void Server_FastUpdate(FVector Location);
    
    // Client RPC (server -> owning client)
    UFUNCTION(Client, Reliable)
    void Client_PlayFireEffects();
    
    // Multicast RPC (server -> all clients)
    UFUNCTION(NetMulticast, Reliable)
    void Multicast_SpawnImpact(FVector Location, FVector Normal);
    
    UFUNCTION()
    void Fire(FVector TargetLocation)
    {
        // Client-side prediction
        PerformFire(TargetLocation);
        
        // Notify server
        Server_Fire(TargetLocation);
    }
}
```

## Gameplay Tags

### Using Gameplay Tags

```angelscript
class AMyCharacter : ACharacter
{
    UPROPERTY()
    FGameplayTagContainer ActiveTags;
    
    UFUNCTION()
    void ApplyTag(FGameplayTag Tag)
    {
        ActiveTags.AddTag(Tag);
    }
    
    UFUNCTION(BlueprintPure)
    bool HasTag(FGameplayTag Tag) const
    {
        return ActiveTags.HasTag(Tag);
    }
    
    UFUNCTION()
    void CheckStatus()
    {
        if (HasTag(n"Status.Stunned"))
        {
            // Cannot move while stunned
            return;
        }
        
        if (HasTag(n"Status.Invulnerable"))
        {
            // Ignore damage
        }
    }
}
```

### Gameplay Tag Literals

Gameplay Tags are bound to the global namespace `GameplayTags`:

```angelscript
// Tag "UI.Action.Escape" becomes:
FGameplayTag EscapeTag = GameplayTags::UI_Action_Escape;
```

## Subsystems

### Using Subsystems

```angelscript
// Game Instance Subsystem
UMyGameSubsystem Subsystem = GetGameInstance().GetSubsystem<UMyGameSubsystem>();

// World Subsystem
USpawnManagerSubsystem SpawnManager = USpawnManagerSubsystem::Get();

// Editor Subsystem (Editor-only)
ULevelEditorSubsystem LevelEditor = ULevelEditorSubsystem::Get();
```

### Creating a Subsystem

```angelscript
// Game Instance Subsystem
class UMyGameSubsystem : UGameInstanceSubsystem
{
    UPROPERTY()
    int32 TotalScore = 0;
    
    UFUNCTION(BlueprintOverride)
    void Initialize(FSubsystemCollectionBase& Collection)
    {
        Super::Initialize(Collection);
        Print("Subsystem initialized!");
    }
    
    UFUNCTION()
    void AddScore(int32 Points)
    {
        TotalScore += Points;
    }
}

// World Subsystem with Tick
class UMyWorldSubsystem : UScriptWorldSubsystem
{
    UFUNCTION(BlueprintOverride)
    void Initialize()
    {
        Print("World Subsystem Initialized!");
    }
    
    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        // Tick logic
    }
}
```

## Editor Scripting

### Editor-Only Script

```angelscript
#if EDITOR

class AEditorHelper : AActor
{
    UPROPERTY(EditAnywhere)
    TArray<AActor> ActorsToProcess;
    
    // Call from editor context menu
    UFUNCTION(CallInEditor, Category = "Editor Tools")
    void OrganizeActors()
    {
        for (AActor Actor : ActorsToProcess)
        {
            if (Actor != nullptr)
            {
                FString NewName = "Organized_" + Actor.GetName();
                Actor.SetActorLabel(NewName);
            }
        }
    }
    
    UFUNCTION(CallInEditor, Category = "Editor Tools")
    void AlignToGrid(float GridSize = 100.0f)
    {
        for (AActor Actor : ActorsToProcess)
        {
            if (Actor != nullptr)
            {
                FVector Location = Actor.GetActorLocation();
                Location.X = FMath::GridSnap(Location.X, GridSize);
                Location.Y = FMath::GridSnap(Location.Y, GridSize);
                Location.Z = FMath::GridSnap(Location.Z, GridSize);
                Actor.SetActorLocation(Location);
            }
        }
    }
}

#endif
```

### Content Browser Extensions

```angelscript
#if EDITOR

class UMyAssetMenuExtension : UScriptAssetMenuExtension
{
    // Which asset types to show menu for
    default SupportedClasses.Add(UTexture2D::StaticClass());
    
    UFUNCTION(CallInEditor, Category = "Texture Actions")
    void ModifyTextureLODBias(FAssetData SelectedAsset, int LODBias = 0)
    {
        UTexture2D Texture = Cast<UTexture2D>(SelectedAsset.GetSoftObjectPath().TryLoad());
        if (Texture != nullptr)
        {
            Texture.Modify();
            Texture.LODBias = LODBias;
        }
    }
}

#endif
```

### Actor Context Menu Extensions

```angelscript
#if EDITOR

class UMyActorMenuExtension : UScriptActorMenuExtension
{
    default SupportedClasses.Add(AActor::StaticClass());
    
    UFUNCTION(CallInEditor)
    void SimpleAction()
    {
        Print("Action executed!");
    }
    
    UFUNCTION(CallInEditor, Category = "My Category")
    void CategorizedAction()
    {
    }
    
    UFUNCTION(CallInEditor, Category = "My Category", Meta = (EditorIcon = "Icons.Link"))
    void ActionWithIcon()
    {
    }
}

#endif
```

### Toolbar Extensions

```angelscript
#if EDITOR

class UMyToolbarExtension : UScriptEditorMenuExtension
{
    default ExtensionPoint = n"LevelEditorToolBar";
    
    UFUNCTION(CallInEditor, Category = "My Tools")
    void ToolbarAction()
    {
        Print("Toolbar button clicked!");
    }
}

#endif
```

### Editor-Only Directories

Folders named `Editor`, `Examples`, or `Dev` are automatically excluded from cooked builds.

### Preprocessor Conditions

```angelscript
#if EDITOR
    // Editor-only code
#endif

#if EDITORONLY_DATA
    // Code that accesses editor-only properties
#endif

#if RELEASE
    // Shipping/Test builds only
#endif

#if TEST
    // Debug/Development/Test builds
#endif
```

## Animation Blueprint Integration

### Thread-Safe Functions

When using multi-threaded animation updates:

```angelscript
class UMyAnimInstance : UAnimInstance
{
    // Thread-safe function - can run on worker thread
    UFUNCTION(BlueprintCallable, Meta = (BlueprintThreadSafe))
    void UpdateIdleState(FAnimUpdateContext& InContext, FAnimNodeReference& InNode)
    {
        // Safe to call from worker thread
        float Weight = InNode.GetInstanceStateWeight();
    }
    
    // Cache game thread data in BlueprintUpdateAnimation
    UPROPERTY()
    FVector CachedVelocity;
    
    UFUNCTION(BlueprintOverride)
    void BlueprintUpdateAnimation(float DeltaTime)
    {
        // This runs on game thread - safe to access actor
        if (GetOwningActor() != nullptr)
        {
            CachedVelocity = GetOwningActor().GetVelocity();
        }
    }
}
```

### BlueprintSafe Functions (UAnimInstance)

Common thread-safe functions available in UAnimInstance:
- `GetRelevantAnimTimeRemaining()` / `GetRelevantAnimTimeRemainingFraction()`
- `GetInstanceStateWeight()` / `GetInstanceMachineWeight()`
- `GetDeltaSeconds()`
- `GetCurveValue()` / `GetCurveValueWithDefault()`
- `WasAnimNotifyTriggeredInStateMachine()`
- `IsSyncGroupBetweenMarkers()`
- `CalculateDirection()`

## Function Libraries

Angelscript simplifies Blueprint Function Library names:

```angelscript
// Common libraries (automatically available)
Math::RandRange(0, 100);
Math::Clamp(Value, 0.0f, 100.0f);

System::SetTimer(this, n"OnTimer", 2.0f, false);
System::DrawDebugSphere(Location, 100.0f, 12, FColor::Red, 2.0f);

Gameplay::GetPlayerCharacter(WorldContext, 0);
Gameplay::OpenLevel(WorldContext, n"NewLevel");

Widget::SetFocusToGameViewport();
```

### Library Name Simplification

| C++ Library | AS Namespace |
|-------------|--------------|
| `UKismetSystemLibrary` | `System::` |
| `UKismetMathLibrary` | `Math::` |
| `UGameplayStatics` | `Gameplay::` |
| `UNiagaraFunctionLibrary` | `Niagara::` |
| `UWidgetBlueprintLibrary` | `Widget::` |

## C++ Binding Guide

### When to Bind C++ to Angelscript

1. **Access non-reflected code**: Use classes not exposed to Blueprint
2. **Missing members**: Access members not exposed to Blueprint
3. **Operators**: Add ==, !=, <, etc. to structs
4. **Performance**: Expose performance-critical code

### Binding Approaches

| Approach | Use Case |
|----------|----------|
| **Manual Binding** | Full control, most powerful |
| **Mixin Binding** | Add methods to existing classes |
| **Inheritance** | Override virtual functions, access protected members |
| **Wrapper Struct** | Wrap non-UStruct types |

### Force Bind UStruct/UClass

For types not automatically bound:

```cpp
// Force bind a UStruct
#define FORCE_BIND_USTRUCT(TypeToBind) \
AS_FORCE_LINK const FAngelscriptBinds::FBind ForceBoundUStruct_##TypeToBind((int32)FAngelscriptBinds::EOrder::Early - 1, []\
{\
    UField* Field = TypeToBind::StaticStruct();\
    Field->SetMetaData(TEXT("ForceAngelscriptBind"), TEXT(""));\
});

// Usage
FORCE_BIND_USTRUCT(FMyCustomStruct)

// Force bind a UClass
#define FORCE_BIND_UCLASS(TypeToBind)\
AS_FORCE_LINK const FAngelscriptBinds::FBind ForceBoundUClass_##TypeToBind((int32)FAngelscriptBinds::EOrder::Early - 1, []\
{\
    UField* Field = TypeToBind::StaticClass();\
    Field->SetMetaData(TEXT("BlueprintType"), TEXT("true"));\
});

// Usage
FORCE_BIND_UCLASS(UMyCustomClass)
```

### Common Binding Pitfalls

1. **UStruct inheritance not recognized**: Bind each struct individually
2. **BlueprintInternalUseOnly**: Functions with this meta won't bind - use Mixin or modify binding code
3. **TMap keys**: Some native structs need special binding to work as TMap keys
4. **Const correctness**: Mixin binding must preserve const for 'this' pointer
5. **Float types**: C++ `float` binds to AS `float32`, `double` to `float64`

### BlueprintInternalUseOnly Workaround

For BlueprintAsyncActionBase and similar:

```cpp
// In your binding code, remove the flag for specific classes
AS_FORCE_LINK const FAngelscriptBinds::FBind Bind_BlueprintAsyncActionBase(FAngelscriptBinds::EOrder::Normal, []
{
    static const FName NAME_BlueprintInternalUseOnly("BlueprintInternalUseOnly");
    
    // Allow Activate function
    if (UClass* Class = UClass::TryFindTypeSlow<UClass>("/Script/Engine.BlueprintAsyncActionBase"))
    {
        if (UFunction* Function = Class->FindFunctionByName("Activate"))
        {
            Function->RemoveMetaData(NAME_BlueprintInternalUseOnly);
        }
    }
});
```

### UInterface Workaround

Since AS doesn't support UInterface directly:

```cpp
// Mixin library for interface functions
UCLASS(Meta = (ScriptMixin = "UObject"))
class UInterfaceMixinLibrary : public UObject
{
    GENERATED_BODY()
    
public:
    UFUNCTION(BlueprintPure, Category = "Interface")
    static bool BP_HasInterface(UObject* Object, const FName& InterfaceName)
    {
        // Check if object implements interface by name
        if (!Object || InterfaceName.IsNone()) return false;
        
        const UClass* InterfaceClass = FindObject<UClass>(ANY_PACKAGE, *InterfaceName.ToString());
        if (!InterfaceClass || !InterfaceClass->IsChildOf(UInterface::StaticClass()))
            return false;
            
        return Object->GetClass()->ImplementsInterface(InterfaceClass);
    }
};
```

## Best Practices

### Naming Conventions

```angelscript
// Classes: PascalCase with prefix
class AMyActor : AActor
class UMyComponent : UActorComponent

// Properties: PascalCase
UPROPERTY()
float MovementSpeed;

// Functions: PascalCase
void UpdatePosition(float DeltaTime);
bool CanJump() const;

// Local variables: camelCase
float deltaTime = GetWorld().DeltaTimeSeconds;
int32 currentHealth = Health;

// Constants: UPPER_SNAKE_CASE
const float MAX_HEALTH = 100.0f;
```

### Performance Tips

```angelscript
// Cache frequently accessed components
class AMyCharacter : ACharacter
{
    private UCharacterMovementComponent MovementComp;
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        MovementComp = UCharacterMovementComponent::Get(this);
    }
}

// Use references for struct containers
TArray<FMyStruct> Items;
for (FMyStruct& Item : Items)  // Use & to avoid copy
{
    Item.Modify();
}

// Prefer Timer over Delay
System::SetTimer(this, n"DelayedFunction", 2.0f, false);
```

### Error Handling

```angelscript
UFUNCTION()
void ProcessActor(AActor Target)
{
    // Always check for null
    if (Target == nullptr)
    {
        Print("Error: Target actor is null", FColor::Red);
        return;
    }
    
    // Validate cast
    AMyCharacter Character = Cast<AMyCharacter>(Target);
    if (Character == nullptr)
    {
        Print("Error: Target is not a MyCharacter", FColor::Red);
        return;
    }
    
    // Check validity
    if (!IsValid(Character))
    {
        Print("Error: Character is pending kill", FColor::Red);
        return;
    }
    
    // Safe to use Character
    Character.TakeDamage(10.0f);
}
```

### Common Pitfalls to Avoid

1. **Don't forget to check null/validity** for UObject references
2. **Don't copy large structs** in loops - use references
3. **Don't use Delay in AS** - prefer SetTimer (Delay can have timing issues)
4. **Don't rely on UStruct inheritance** in AS - bind each struct individually
5. **Don't mix cpp and AS GameplayMessageSubsystem** - can cause issues
6. **Don't use BlueprintInternalUseOnly functions** directly - need binding workaround

## Debugging

### Print Functions

```angelscript
UFUNCTION()
void DebugInfo()
{
    // Simple print
    Print("Hello World");
    
    // Print with color
    Print("Warning message", FColor::Yellow);
    Print("Error message", FColor::Red);
    
    // Print to screen with duration
    Print("Important message", FColor::Green, 5.0f);
    
    // Format strings
    FString Formatted = f"Health: {Health}/{MaxHealth}";
    Print(Formatted);
    
    // Log to output log
    System::LogString(f"Debug: {GetName()}");
}
```

### Draw Debug

```angelscript
UFUNCTION()
void DrawDebugInfo()
{
    FVector Location = GetActorLocation();
    
    // Debug shapes
    System::DrawDebugSphere(Location, 100.0f, 12, FColor::Red, 2.0f);
    System::DrawDebugLine(Location, Location + FVector::UpVector * 200, FColor::Green, 2.0f);
    System::DrawDebugBox(Location, FVector(50, 50, 50), FColor::Blue, true, 2.0f);
    
    // Debug text
    System::DrawDebugString(Location + FVector::UpVector * 100, "Player", nullptr, FColor::White, 2.0f);
}
```

### VSCode Debugging

1. Set breakpoints in VSCode
2. Press F5 to attach to running editor
3. Use Watch window to inspect variables
4. Call Stack shows AS and C++ frames

## Quick Reference

### Common UPROPERTY Specifiers

| Specifier | Description |
|-----------|-------------|
| `EditAnywhere` | Editable in defaults and instances (default) |
| `EditDefaultsOnly` | Editable only in blueprint defaults |
| `EditInstanceOnly` | Editable only on placed instances |
| `VisibleAnywhere` | Visible but not editable |
| `BlueprintReadOnly` | Readable in blueprints, not writable |
| `BlueprintReadWrite` | Readable and writable in blueprints (default) |
| `BlueprintHidden` | Not accessible from blueprints |
| `Category = "Name"` | Organizes property in editor |
| `Replicated` | Synchronized over network |
| `DefaultComponent` | Creates component automatically |
| `meta = (ClampMin = "0")` | Adds min/max clamping |

### Common UFUNCTION Specifiers

| Specifier | Description |
|-----------|-------------|
| `BlueprintCallable` | Can be called from blueprints (default for UFUNCTION) |
| `BlueprintPure` | Pure function (no side effects) |
| `BlueprintEvent` | Can be implemented in blueprints |
| `BlueprintOverride` | Overrides existing blueprint event |
| `BlueprintAuthorityOnly` | Only runs if has authority |
| `Server` | Server RPC |
| `Client` | Client RPC |
| `NetMulticast` | Multicast RPC |
| `Reliable` | Guaranteed delivery (default) |
| `Unreliable` | No delivery guarantee |
| `CallInEditor` | Can be called from editor |
| `Meta = (BlueprintThreadSafe)` | Safe for multi-threaded animation |

### Operator Bindings

| AS Operator | Binding Name |
|-------------|--------------|
| `=` | `opAssign` |
| `==` | `opEquals` |
| `!=` | `opNotEquals` |
| `<`, `>`, `<=`, `>=` | `opCmp` (returns int: -1, 0, 1) |
| `+` | `opAdd` |
| `-` | `opSub` |
| `*` | `opMul` |
| `/` | `opDiv` |
| `+=` | `opAddAssign` |
| `-=` | `opSubAssign` |

## Useful Resources

- **Official Documentation**: https://angelscript.hazelight.se/
- **API Reference**: https://angelscript.hazelight.se/api/
- **Discord Community**: https://discord.gg/39wmC2e
- **GitHub Repository**: https://github.com/Hazelight/UnrealEngine-Angelscript
- **VSCode Extension**: https://marketplace.visualstudio.com/items?itemName=Hazelight.unreal-angelscript
- **Chinese Community Column**: https://zhuanlan.zhihu.com/column/c_1853873590887403520
