/**
 * 
 */
enum EHazePointOfInterestFocusTargetType
{	
	// The other player is focused
	OtherPlayer, 

	// Focus on an actor
	Actor,

	// Generate a custom location
	Custom,

	MAX,
}

/**
 * 
 */
struct FHazePointOfInterestFocusTargetInfo
{
	UPROPERTY(EditAnywhere, Category = "Target")
	private EHazePointOfInterestFocusTargetType TargetType = EHazePointOfInterestFocusTargetType::Actor;

	// Focus on this specific actor
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Target", Meta = (EditCondition = "TargetType == EHazePointOfInterestFocusTargetType::Actor", EditConditionHides))
	private AActor Actor = nullptr;

	// Focus on a specific point detected by a 'UHazeCameraWeightedFocusTargetCustomGetter'
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Target", Meta = (EditCondition = "TargetType == EHazePointOfInterestFocusTargetType::Custom", EditConditionHides))
	private TSubclassOf<UHazeCameraWeightedFocusTargetCustomGetter> CustomGetter = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Target")
	FHazeCameraPointOfInterestTargetAdvancedInfo AdvancedSettings;

	UPROPERTY(BlueprintHidden, NotEditable)
	private USceneComponent InternalSpecificComponent = nullptr;

	UPROPERTY(BlueprintHidden, NotEditable)
	private FName InternalSpecificComponentSocket = NAME_None;

	UPROPERTY(BlueprintHidden, NotEditable)
	bool bHasInternalWorldLocation = false;

	UPROPERTY(BlueprintHidden, NotEditable)
	FVector InternalWorldLocation = FVector::ZeroVector;


	private void Clear()
	{
		TargetType = EHazePointOfInterestFocusTargetType::MAX;
		Actor = nullptr;
		InternalSpecificComponent = nullptr;
		InternalSpecificComponentSocket = NAME_None;
		bHasInternalWorldLocation = false;
		InternalWorldLocation = FVector::ZeroVector;
	}

	void SetFocusToOtherPlayer()
	{
		Clear();
		TargetType = EHazePointOfInterestFocusTargetType::OtherPlayer;
	}

	void SetFocusToActor(AActor InActor)
	{
		Clear();
		TargetType = EHazePointOfInterestFocusTargetType::Actor;
		Actor = InActor;
	}

	void SetFocusToComponent(USceneComponent Component)
	{
		Clear();
		InternalSpecificComponent = Component;
	}

	void SetFocusToMeshComponent(UMeshComponent Component, FName Socket = NAME_None)
	{
		Clear();
		InternalSpecificComponent = Component;
	} 

	void SetFocusToWorldLocation(FVector WorldLocation)
	{
		Clear();
		bHasInternalWorldLocation = true;
		InternalWorldLocation = WorldLocation;
	}

	void SetFocusToCustom(TSubclassOf<UHazeCameraWeightedFocusTargetCustomGetter> Type)
	{
		Clear();
		TargetType = EHazePointOfInterestFocusTargetType::Custom;
		CustomGetter = Type;
	}

	void SetLocalOffset(FVector Offset) property
	{
		AdvancedSettings.LocalOffset = Offset;
	}

	void SetWorldOffset(FVector Offset) property
	{
		AdvancedSettings.WorldOffset = Offset;
	}

	void SetViewOffset(FVector Offset) property
	{
		AdvancedSettings.ViewOffset = Offset;
	}

	FVector GetFocusLocation(AHazePlayerCharacter Player) const
	{
		return GetFocusLocation(Player.GetViewRotation(), Player);
	}

	FVector GetFocusLocation(FRotator CurrentViewRotation, AHazePlayerCharacter Player) const
	{
		FVector OutWorldLocation = FVector::ZeroVector;
		FQuat LocalRotation = FQuat::Identity;

		// Test for actors
		{
			if(TargetType == EHazePointOfInterestFocusTargetType::OtherPlayer)
			{
				OutWorldLocation = Player.OtherPlayer.GetFocusLocation();
				LocalRotation = Player.OtherPlayer.GetActorQuat();
			}
			else if(TargetType == EHazePointOfInterestFocusTargetType::Actor)
			{
				if(Actor != nullptr)
				{
					auto HazeActor = Cast<AHazeActor>(Actor);
					if(HazeActor != nullptr)
						OutWorldLocation = HazeActor.GetFocusLocation();
					else
						OutWorldLocation = Actor.GetActorLocation();
					LocalRotation = Actor.GetActorQuat();
				}
			}	
			else if(TargetType == EHazePointOfInterestFocusTargetType::Custom)
			{
				if(CustomGetter.IsValid())
				{
					auto Getter = Cast<UHazeCameraWeightedFocusTargetCustomGetter>(CustomGetter.Get().DefaultObject);
					OutWorldLocation = Getter.GetFocusLocation();

					auto Component = Getter.GetFocusComponent();
					if(Component != nullptr)
						LocalRotation = Getter.GetFocusComponent().ComponentQuat;
				}
			}	
			else if(InternalSpecificComponent != nullptr)
			{
				if(InternalSpecificComponentSocket != NAME_None)
				{
					FTransform SocketTransform = Cast<UMeshComponent>(InternalSpecificComponent).GetSocketTransform(InternalSpecificComponentSocket);
					OutWorldLocation = SocketTransform.Location;
					LocalRotation = SocketTransform.Rotation;
				}
				else
				{
					OutWorldLocation = InternalSpecificComponent.WorldLocation;
					LocalRotation = InternalSpecificComponent.ComponentQuat;
				}	
			}
			else if(bHasInternalWorldLocation)
			{
				OutWorldLocation = InternalWorldLocation;		
			}
		}

		OutWorldLocation += AdvancedSettings.WorldOffset;
		OutWorldLocation += LocalRotation.RotateVector(AdvancedSettings.LocalOffset);
		OutWorldLocation += CurrentViewRotation.RotateVector(AdvancedSettings.ViewOffset);	
		return OutWorldLocation;
	}

	USceneComponent GetFocusComponent(AHazePlayerCharacter Player) const
	{
		if(TargetType == EHazePointOfInterestFocusTargetType::OtherPlayer)
		{
			return Player.OtherPlayer.RootComponent;
		}
		else if(InternalSpecificComponent != nullptr)
		{
			return InternalSpecificComponent;	
		}
		else if(TargetType == EHazePointOfInterestFocusTargetType::Actor && Actor != nullptr)
		{
			return Actor.RootComponent;
		}	
		else if(TargetType == EHazePointOfInterestFocusTargetType::Custom && CustomGetter != nullptr)
		{
			return Cast<UHazeCameraWeightedFocusTargetCustomGetter>(CustomGetter.Get().DefaultObject).GetFocusComponent();
		}
		return nullptr;
	}

	FRotator GetFocusRotation(AHazePlayerCharacter Player, bool bMatchFocusDirection = false) const
	{
		check(IsValid());
		FVector ViewLocation = Player.GetViewLocation();
		FRotator ViewRotation = Player.GetViewRotation();
		auto FocusComponent = GetFocusComponent(Player);
		if (!bMatchFocusDirection || FocusComponent == nullptr)
		{
			//const FVector ViewLocation = Player.GetViewLocation();
			const FVector FocusLocation = GetFocusLocation(ViewRotation, Player);
			const FVector ViewDir = (FocusLocation - ViewLocation);
			if(!ViewDir.IsNearlyZero())
				return ViewDir.Rotation();
			else
				return ViewRotation;
		}
	
		return FocusComponent.WorldRotation;
	}

	bool IsValid() const
	{
		if(TargetType == EHazePointOfInterestFocusTargetType::OtherPlayer)
			return true;

		else if(TargetType == EHazePointOfInterestFocusTargetType::Actor)
			return Actor != nullptr;
		
		else if(TargetType == EHazePointOfInterestFocusTargetType::Custom)
			return CustomGetter != nullptr;

		else if(bHasInternalWorldLocation)
			return true;

		else if(InternalSpecificComponent != nullptr)
			return true;

		return false;
	}

	FString ToString() const
	{
		FString Out = "";
		Out += f"Type {TargetType}\n";
	
		if(bHasInternalWorldLocation)
			Out += f"{InternalWorldLocation}";
		else if(CustomGetter != nullptr)
			Out += f"Custom: {CustomGetter}";
		else
		{
			if(InternalSpecificComponent != nullptr)
				Out += f"{InternalSpecificComponent.GetOwner()} | {InternalSpecificComponent}";
			if(Actor != nullptr)
				Out += f"{Actor}";
		}

		return Out;
	}
	
};

/**
 * 
 */
struct FHazeCameraPointOfInterestTargetAdvancedInfo
{
	// Modify focus location by this offset in world space.
	UPROPERTY(EditAnywhere, AdvancedDisplay)	
	FVector WorldOffset = FVector::ZeroVector;

	// Modify focus location by this offset in focus actor local space.
	UPROPERTY(EditAnywhere, AdvancedDisplay)	
	FVector LocalOffset = FVector::ZeroVector;

	// Modify focus location by this offset in viewing player view point space
	UPROPERTY(EditAnywhere, AdvancedDisplay)
	FVector ViewOffset = FVector::ZeroVector;
}

/**
 * 
 */
namespace HazePointOfInterestStatics
{
	UFUNCTION(BlueprintPure, Category = "PointOfInterest", Meta = (AutoSplit = "Settings"))
	FHazePointOfInterestFocusTargetInfo FocusOnActor(AActor Actor, FHazeCameraPointOfInterestTargetAdvancedInfo Settings)
	{
		devCheck(Actor != nullptr, "Added a point of interest 'FocusOnActor', but 'Actor' was null");

		FHazePointOfInterestFocusTargetInfo Out;
		Out.SetFocusToActor(Actor);
		Out.AdvancedSettings = Settings;
		return Out;
	}

	UFUNCTION(BlueprintPure, Category = "PointOfInterest", Meta = (AutoSplit = "Settings"))
	FHazePointOfInterestFocusTargetInfo FocusOnComponent(USceneComponent Component, FHazeCameraPointOfInterestTargetAdvancedInfo Settings)
	{
		devCheck(Component != nullptr, "Added a point of interest 'FocusOnComponent', but 'Component' was null");

		FHazePointOfInterestFocusTargetInfo Out;
		Out.SetFocusToComponent(Component);
		Out.AdvancedSettings = Settings;
		return Out;
	}
}
