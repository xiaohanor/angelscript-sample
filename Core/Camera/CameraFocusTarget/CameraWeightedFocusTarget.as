/**
 * 
*/
enum EHazeCameraWeightedFocusTargetType
{
	// Focus on the actor controlled by the user (Usually the player)
	User UMETA(DisplayName="User Controlled Actor"), 

	// Focus the actor controlled by the other user (Usually the other player)
	OtherUser UMETA(DisplayName="Other User Controlled Actor"), 	
	
	// Focus on the other player
	OtherPlayer, 

	// Always focus mio
	Mio,

	// Always focus zoe
	Zoe,

	// Focus on a specific actor
	Actor,

	// A custom way of getting targets
	Custom,

	// Invalid
	MAX UMETA(Hidden),
}

/** A getter object for making custom focus targets */
UCLASS(Abstract)
class UHazeCameraWeightedFocusTargetCustomGetter : UObject
{
	USceneComponent GetFocusComponent() const
	{
		devError(f"{this} has not implemented 'GetFocusComponent'");
		return nullptr;
	}

	FVector GetFocusLocation() const
	{
		devError(f"{this} has not implemented 'GetFocusLocation'");
		return FVector::ZeroVector;
	}

	void GetEditorPreviewFocusTransform(FTransform CustomTargetTransform, FRotator ViewRotation, FVector& OutWorldLocation, FRotator& OutWorldRotation) const
	{
		OutWorldLocation = CustomTargetTransform.Location;
		OutWorldRotation = CustomTargetTransform.Rotator();
	}
}

/**
 * 
 */
struct FHazeCameraWeightedFocusTargetInfo
{
	UPROPERTY(EditAnywhere, Category = "Target")
	private EHazeCameraWeightedFocusTargetType TargetType = EHazeCameraWeightedFocusTargetType::User;

	// Focus on this specific actor
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Target", Meta = (EditCondition = "TargetType == EHazeCameraWeightedFocusTargetType::Actor", EditConditionHides))
	private AActor Actor = nullptr;

	// Focus on a specific point detected by a 'UHazeCameraWeightedFocusTargetCustomGetter'
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Target", Meta = (EditCondition = "TargetType == EHazeCameraWeightedFocusTargetType::Custom", EditConditionHides))
	private TSubclassOf<UHazeCameraWeightedFocusTargetCustomGetter> CustomGetter = nullptr;

	UPROPERTY(BlueprintHidden, NotEditable)
	private USceneComponent InternalSpecificComponent = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Target", AdvancedDisplay)
	FHazeCameraWeightedFocusTargetAdvancedInfo AdvancedSettings;

	private void Clear()
	{
		TargetType = EHazeCameraWeightedFocusTargetType::MAX;
		Actor = nullptr;
		InternalSpecificComponent = nullptr;
	}

	// Focus on the cameras user
	void SetFocusToUser()
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::User;
	}

	// Focus on the cameras other user
	void SetFocusToOtherUser()
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::OtherUser;
	}

	// Focus on the other player
	void SetFocusToOtherPlayer()
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::OtherPlayer;
	}

	void SetFocusToPlayerMio()
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::Mio;
	}

	void SetFocusToPlayerZoe()
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::Zoe;
	}

	void SetFocusToActor(AHazeActor InActor)
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::Actor;
		Actor = InActor;
	}

	void SetFocusToComponent(USceneComponent Component)
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::Actor;	
		InternalSpecificComponent = Component;
	}

	void SetFocusToCustom(TSubclassOf<UHazeCameraWeightedFocusTargetCustomGetter> Type)
	{
		Clear();
		TargetType = EHazeCameraWeightedFocusTargetType::Custom;	
		CustomGetter = Type;
	}

	EHazeCameraWeightedFocusTargetType GetFocusTargetType() const
	{
		return TargetType;
	}

	bool CanPlayerFocusOn(AHazePlayerCharacter User, AHazePlayerCharacter OtherUser) const
	{
		if(AdvancedSettings.UsedBy == EHazeSelectPlayer::None)
			return false;
		if(AdvancedSettings.UsedBy == EHazeSelectPlayer::Mio && User.IsZoe())
			return false;
		if(AdvancedSettings.UsedBy == EHazeSelectPlayer::Zoe && User.IsMio())
			return false;
		if(TargetType == EHazeCameraWeightedFocusTargetType::OtherUser && OtherUser == nullptr)
			return false;
		
		// This is not a player target focus,
		// So we don't need to validate if we can focus on the player
		AHazePlayerCharacter PlayerTarget = GetPlayerTarget(User, OtherUser);
		if(PlayerTarget == nullptr)
			return true;

		if(!PlayerFocus::CanFocusOnPlayer(PlayerTarget))
			return false;

		return true;
	}

	private AHazePlayerCharacter GetPlayerTarget(AHazePlayerCharacter User, AHazePlayerCharacter OtherUser) const
	{
		if(TargetType == EHazeCameraWeightedFocusTargetType::User)
			return User;
		if(TargetType == EHazeCameraWeightedFocusTargetType::OtherUser)
			return OtherUser;
		if(TargetType == EHazeCameraWeightedFocusTargetType::OtherPlayer)
			return User.OtherPlayer;
		if(TargetType == EHazeCameraWeightedFocusTargetType::Mio)
			return Game::GetMio();
		if(TargetType == EHazeCameraWeightedFocusTargetType::Zoe)
			return Game::GetZoe();

		if(TargetType == EHazeCameraWeightedFocusTargetType::Actor)
		{
			if(InternalSpecificComponent != nullptr)
				return Cast<AHazePlayerCharacter>(InternalSpecificComponent.Owner);
			else if(Actor != nullptr)
				return Cast<AHazePlayerCharacter>(Actor);
		}

		else if(TargetType == EHazeCameraWeightedFocusTargetType::Custom)
		{
			if(CustomGetter.IsValid())
			{
				auto Comp = Cast<UHazeCameraWeightedFocusTargetCustomGetter>(CustomGetter.Get().DefaultObject).GetFocusComponent();
				if(Comp != nullptr)
					return Cast<AHazePlayerCharacter>(Comp.Owner);
			}
		}

		return nullptr;
	}

	bool IsMarkedPrimary() const
	{
		return AdvancedSettings.bMarkAsPrimary;
	}

	bool IsValid() const
	{
		if(TargetType == EHazeCameraWeightedFocusTargetType::MAX)
			return false;

		else if(TargetType == EHazeCameraWeightedFocusTargetType::Custom)
			return CustomGetter != nullptr;

		else if(TargetType != EHazeCameraWeightedFocusTargetType::Actor)
			return true;

		else if(InternalSpecificComponent != nullptr)
			return true;

		else if(Actor != nullptr)
			return true;

		return false;
	}

	bool Equals(FHazeCameraWeightedFocusTargetInfo Other) const
	{
		if(TargetType != Other.TargetType)
			return false;

		if(InternalSpecificComponent != Other.InternalSpecificComponent)
			return false;

		if(Actor != Other.Actor)
			return false;

		if(CustomGetter != Other.CustomGetter)
			return false;

		if(!AdvancedSettings.LocalOffset.Equals(Other.AdvancedSettings.LocalOffset))
			return false;

		if(!AdvancedSettings.ViewOffset.Equals(Other.AdvancedSettings.ViewOffset))
			return false;

		if(!AdvancedSettings.WorldOffset.Equals(Other.AdvancedSettings.WorldOffset))
			return false;

		if(AdvancedSettings.bMarkAsPrimary != Other.AdvancedSettings.bMarkAsPrimary)
			return false;

		if(AdvancedSettings.UsedBy != Other.AdvancedSettings.UsedBy)
			return false;

		if(AdvancedSettings.Weight != Other.AdvancedSettings.Weight)
			return false;

		return true;
	}	

	void SetWorldOffset(FVector Offset) property
	{
		AdvancedSettings.WorldOffset = Offset;
	}

	void SetLocalOffset(FVector Offset) property
	{
		AdvancedSettings.LocalOffset = Offset;
	}

	void SetViewOffset(FVector Offset) property
	{
		AdvancedSettings.ViewOffset = Offset;
	}

	USceneComponent GetFocusComponent(AHazePlayerCharacter Player) const
	{
		if(TargetType == EHazeCameraWeightedFocusTargetType::User)
		{
			return Player.RootComponent;
		}
		else if(TargetType == EHazeCameraWeightedFocusTargetType::OtherPlayer 
			|| TargetType == EHazeCameraWeightedFocusTargetType::OtherUser)
		{
			return Player.OtherPlayer.RootComponent;
		}
		else if(TargetType == EHazeCameraWeightedFocusTargetType::Mio)
		{
			return Game::Mio.RootComponent;
		}
		else if(TargetType == EHazeCameraWeightedFocusTargetType::Zoe)
		{
			return Game::Zoe.RootComponent;
		}
		else if(TargetType == EHazeCameraWeightedFocusTargetType::Actor)
		{
			if(InternalSpecificComponent != nullptr)
			{
				return InternalSpecificComponent;
			}
			else if(Actor != nullptr)
			{
				return Actor.RootComponent;
			}
		}
		else if(TargetType == EHazeCameraWeightedFocusTargetType::Custom)
		{
			if(CustomGetter.IsValid())
			{
				return Cast<UHazeCameraWeightedFocusTargetCustomGetter>(CustomGetter.Get().DefaultObject).GetFocusComponent();
			}
		}
		
		return nullptr;	
	}

	FVector GetFocusLocation(AHazePlayerCharacter Player) const
	{
		// This function can only be used from specific actors.
		FVector OutWorldLocation;
		FQuat LocalRotation = FQuat::Identity;

		// Test for actors
		{
			if(TargetType == EHazeCameraWeightedFocusTargetType::User)
			{
				OutWorldLocation = Player.GetFocusLocation();
				LocalRotation = Player.GetActorQuat();
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::OtherPlayer 
				|| TargetType == EHazeCameraWeightedFocusTargetType::OtherUser)
			{
				OutWorldLocation = Player.OtherPlayer.GetFocusLocation();
				LocalRotation = Player.OtherPlayer.GetActorQuat();
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Mio)
			{
				OutWorldLocation = Game::Mio.GetFocusLocation();
				LocalRotation = Game::Mio.GetActorQuat();
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Zoe)
			{
				OutWorldLocation = Game::Zoe.GetFocusLocation();
				LocalRotation = Game::Zoe.GetActorQuat();
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Actor)
			{
				if(InternalSpecificComponent != nullptr)
				{
					OutWorldLocation = InternalSpecificComponent.WorldLocation;
					LocalRotation = InternalSpecificComponent.ComponentQuat;
				}
				else if(Actor != nullptr)
				{
					auto HazeActor = Cast<AHazeActor>(Actor);
					if(HazeActor != nullptr)
						OutWorldLocation = HazeActor.GetFocusLocation();
					else
						OutWorldLocation = Actor.GetActorLocation();
					LocalRotation = Actor.GetActorQuat();	
				}
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Custom)
			{
				if(CustomGetter.IsValid())
				{
					return Cast<UHazeCameraWeightedFocusTargetCustomGetter>(CustomGetter.Get().DefaultObject).GetFocusLocation();
				}
			}	
		}

		OutWorldLocation += AdvancedSettings.WorldOffset;
		OutWorldLocation += LocalRotation.RotateVector(AdvancedSettings.LocalOffset);
		OutWorldLocation += Player.GetViewRotation().RotateVector(AdvancedSettings.ViewOffset);	
		return OutWorldLocation;
	}

	float GetFocusWeight(AHazePlayerCharacter Player) const
	{
		auto Settings = UPlayerFocusTargetSettings::GetSettings(Player);
		return AdvancedSettings.Weight * Settings.WeightMultiplier;
	}


#if EDITOR
	float GetEditorPreviewWeight() const
	{
		return AdvancedSettings.Weight;
	}

	void GetEditorPreviewFocusTransform(FTransform PlayerTransform, FRotator ViewRotation, FVector& OutWorldLocation, FRotator& OutWorldRotation) const
	{
		OutWorldLocation = FVector::ZeroVector;
		FQuat LocalRotation = FQuat::Identity;

		// Test for actors
		{
			if(TargetType == EHazeCameraWeightedFocusTargetType::User)
			{
				OutWorldLocation = PlayerTransform.Location;
				LocalRotation = PlayerTransform.Rotation;
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::OtherPlayer 
				|| TargetType == EHazeCameraWeightedFocusTargetType::OtherUser)
			{
				OutWorldLocation = PlayerTransform.Location;
				LocalRotation = PlayerTransform.Rotation;
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Mio)
			{
				OutWorldLocation = PlayerTransform.Location;
				LocalRotation = PlayerTransform.Rotation;
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Zoe)
			{
				OutWorldLocation = PlayerTransform.Location;
				LocalRotation = PlayerTransform.Rotation;
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Actor)
			{
				if(InternalSpecificComponent != nullptr)
				{
					OutWorldLocation = InternalSpecificComponent.WorldLocation;
					LocalRotation = InternalSpecificComponent.ComponentQuat;
				}
				else if(Actor != nullptr)
				{
					auto HazeActor = Cast<AHazeActor>(Actor);
					if(HazeActor != nullptr)
						OutWorldLocation = HazeActor.GetFocusLocation();
					else
						OutWorldLocation = Actor.GetActorLocation();
					LocalRotation = Actor.GetActorQuat();	
				}
			}
			else if(TargetType == EHazeCameraWeightedFocusTargetType::Custom)
			{
				if(CustomGetter.IsValid())
				{
					Cast<UHazeCameraWeightedFocusTargetCustomGetter>(CustomGetter.Get().DefaultObject).GetEditorPreviewFocusTransform(PlayerTransform, ViewRotation, OutWorldLocation, OutWorldRotation);
				}
			}		
		}

		OutWorldLocation += AdvancedSettings.WorldOffset;
		OutWorldLocation += LocalRotation.RotateVector(AdvancedSettings.LocalOffset);
		OutWorldLocation += ViewRotation.RotateVector(AdvancedSettings.ViewOffset);	

		OutWorldRotation = LocalRotation.Rotator();
	}

	bool GetEditorPreviewShouldFocusOnUser() const
	{
		if(TargetType == EHazeCameraWeightedFocusTargetType::User)
			return true;

		if(TargetType == EHazeCameraWeightedFocusTargetType::Mio)
			return true;

		return false;
	}

	bool GetEditorPreviewShouldFocusOnOtherUser() const
	{
		if(TargetType == EHazeCameraWeightedFocusTargetType::OtherUser)
			return true;

		if(TargetType == EHazeCameraWeightedFocusTargetType::OtherPlayer)
			return true;

		if(TargetType == EHazeCameraWeightedFocusTargetType::Zoe)
			return true;

		return false;
	}

	FName GetEditorPreviewPlayerDebugType() const
	{
		if(Actor != nullptr)
			return NAME_None;
		if(InternalSpecificComponent != nullptr)
			return NAME_None;

		if(TargetType == EHazeCameraWeightedFocusTargetType::Custom)
			return n"Custom";

		if(TargetType == EHazeCameraWeightedFocusTargetType::User)
			return n"Player";
		if(TargetType == EHazeCameraWeightedFocusTargetType::OtherUser || TargetType == EHazeCameraWeightedFocusTargetType::OtherPlayer)
			return n"OtherPlayer";
		if(TargetType == EHazeCameraWeightedFocusTargetType::Mio)
			return n"Mio";
		if(TargetType == EHazeCameraWeightedFocusTargetType::Zoe)
			return n"Zoe";

		return NAME_None;
	}

	FLinearColor GetEditorPreviewDebugColor() const
	{
		FName Type = GetEditorPreviewPlayerDebugType();
		if(Type == n"Player")
			return FLinearColor::LucBlue;
		if(Type == n"OtherPlayer")
			return FLinearColor::Blue;
		if(Type == n"Mio")
			return FLinearColor::Yellow;
		if(Type == n"Zoe")
			return FLinearColor::Purple;
		if(Type == n"Custom")
			return FLinearColor::DPink;
		return FLinearColor::Gray;
	}

#endif
	
	void GetDebugInfo(FString& Out) const
	{
		#if TEST
		Out += f"Type {TargetType}\n";
		
		if(InternalSpecificComponent != nullptr)
		{
			#if EDITOR
			Out += f"{InternalSpecificComponent.GetOwner().GetActorLabel()} | {InternalSpecificComponent}";
			#else
			Out += f"{InternalSpecificComponent.GetOwner().GetName()} | {InternalSpecificComponent}";
			#endif
		}
		else if(Actor != nullptr)
		{
			#if EDITOR
			Out += f"{Actor.GetActorLabel()}";
			#else
			Out += f"{Actor.GetName()}";
			#endif
		}

		Out += f"World Offset {ToCompactVector(AdvancedSettings.WorldOffset)}\n";
		Out += f"Local Offset {ToCompactVector(AdvancedSettings.LocalOffset)}\n";
		Out += f"ViewOffset Offset {ToCompactVector(AdvancedSettings.ViewOffset)}\n";
		#endif
	}

	private FString ToCompactVector(FVector Vec) const
	{
		if(Vec.IsNearlyZero())
		{
			return "V(0)";
		}

		FString ReturnString = "";
		bool bIsEmpty = true;

		if(!Math::IsNearlyZero(Vec.X))
		{
			ReturnString += f"X:{Vec.X :.3}";
			bIsEmpty = false;
		}

		if(!Math::IsNearlyZero(Vec.Y))
		{
			if(!bIsEmpty)
				ReturnString += ", ";
			ReturnString += f"Y:{Vec.Y :.3}";
			bIsEmpty = false;
		}
		
		if(!Math::IsNearlyZero(Vec.Z))
		{
			if(!bIsEmpty)
				ReturnString += ", ";
			ReturnString += f"Z:{Vec.Z :.3}";
			bIsEmpty = false;
		}

		return ReturnString;
	}
};

/**
 * 
 */
struct FHazeCameraWeightedFocusTargetAdvancedInfo
{
	// Modify focus location by this offset in world space.
	UPROPERTY(EditAnywhere, AdvancedDisplay)	
	FVector WorldOffset = FVector::ZeroVector;

	// Modify focus location by this offset in focus actor local space.
	UPROPERTY(EditAnywhere, AdvancedDisplay, meta = (DisplayName = "Target Actor Local Offset"))	
	FVector LocalOffset = FVector::ZeroVector;

	// Modify focus location by this offset in viewing player view point space
	UPROPERTY(EditAnywhere, AdvancedDisplay)
	FVector ViewOffset = FVector::ZeroVector;

	// How much camera will favor this focus target compared to other ones.
    UPROPERTY(EditAnywhere, AdvancedDisplay)
    float Weight = 1.0;

	// Primary targets can be used for custom behaviors in cameras
    UPROPERTY(EditAnywhere, AdvancedDisplay)
    bool bMarkAsPrimary = false;

	// Which players will use this focus target?
    UPROPERTY(EditAnywhere, AdvancedDisplay)
	EHazeSelectPlayer UsedBy = EHazeSelectPlayer::Both;

	void SetWeight(float NewWeight)
	{
		Weight = NewWeight;
	}
}


/**
 * 
 */
namespace HazeCameraWeightedFocusTargetStatics
{
	UFUNCTION(BlueprintPure, Category = "FocusTarget", Meta = (AutoSplit = "Settings"))
	FHazeCameraWeightedFocusTargetInfo FocusOnActor(AHazeActor Actor, FHazeCameraWeightedFocusTargetAdvancedInfo Settings)
	{
		devCheck(Actor != nullptr, "Added a focus target 'FocusOnActor', but 'Actor' was null");

		FHazeCameraWeightedFocusTargetInfo Out;
		Out.SetFocusToActor(Actor);
		Out.AdvancedSettings = Settings;
		return Out;
	}

	UFUNCTION(BlueprintPure, Category = "FocusTarget", Meta = (AutoSplit = "Settings"))
	FHazeCameraWeightedFocusTargetInfo FocusOnComponent(USceneComponent Component, FHazeCameraWeightedFocusTargetAdvancedInfo Settings)
	{
		devCheck(Component != nullptr, "Added a focus target 'FocusOnComponent', but 'Component' was null");

		FHazeCameraWeightedFocusTargetInfo Out;
		Out.SetFocusToComponent(Component);
		Out.AdvancedSettings = Settings;
		return Out;
	}
}



/**
 * 
 */
struct FInternalInstigatedCameraWeightedRuntimeTarget
{
	FInstigator Instigator;
	FHazeCameraWeightedFocusTargetInfo Target;

	EHazeSelectPlayer UsedByPlayer = EHazeSelectPlayer::Both;
};

/**
 * 
 */
struct FCameraWeightedTargetGetterSettings
{
	bool bIncludeMarkedPrimaryTargets = true;
	bool bIncludeUnMarkedTargets = true;	
	bool bCanIncludeOtherUser = true;
	bool bIncludeRuntimeSettings = true;
	bool bIncludeDebugInfo = false;
}

enum EHazeCameraFinalizedWeightedFocusTargetPlayerType
{
	None,
	Self,
	Other
}

/**
 * 
 */
struct FHazeCameraFinalizedWeightedFocusTargetInfo
{
	FVector Location = FVector::ZeroVector;
	FRotator Rotation = FRotator::ZeroRotator;
	float Weight = 1;
	EHazeCameraFinalizedWeightedFocusTargetPlayerType PlayerTarget = EHazeCameraFinalizedWeightedFocusTargetPlayerType::None;

	#if TEST
	FString DebugActorName = "";
	FString DebugInfo = "";
	#endif

	void Fill(AHazePlayerCharacter Player, FHazeCameraWeightedFocusTargetInfo Other)
	{
		auto Comp =  Other.GetFocusComponent(Player);
		Location = Other.GetFocusLocation(Player);
		Weight = Other.GetFocusWeight(Player);

		PlayerTarget = EHazeCameraFinalizedWeightedFocusTargetPlayerType::None;
		if (Comp != nullptr)
		{
			Rotation = Comp.WorldRotation;
			auto TargetPlayer = Cast<AHazePlayerCharacter>(Comp.Owner);
			if(TargetPlayer != nullptr && Player != nullptr)
			{
				if(TargetPlayer == Player)
					PlayerTarget = EHazeCameraFinalizedWeightedFocusTargetPlayerType::Self;
				else
					PlayerTarget = EHazeCameraFinalizedWeightedFocusTargetPlayerType::Other;
			}
		}
	}

	void SetActorDebugName(AActor Actor)
	{
		#if TEST
		#if EDITOR	
		DebugActorName = Actor.GetActorLabel();
		#else
		DebugActorName = Actor.GetName().ToString();
		#endif
		#endif
	}
	
}

struct FFocusTargets
{
	TArray<FHazeCameraFinalizedWeightedFocusTargetInfo> Targets;

	void Add(FHazeCameraFinalizedWeightedFocusTargetInfo Info)
	{
		Targets.Add(Info);
	}

	void Add(FFocusTargets MoreTargets)
	{
		for(auto It : MoreTargets.Targets)
		{
			Targets.AddUnique(It);
		}
	}

	void Reset()
	{
		Targets.Empty();
	}

	void BalanceWeight()
	{
		float TotalWeight = 0;
		for(auto& It : Targets)
		{
			TotalWeight += It.Weight;
		}
		BalanceWeight(TotalWeight);
	}

	void BalanceWeight(float TotalWeight)
	{
		devCheck(TotalWeight > 0);

		// Fixup the total weight
		for(auto& It : Targets)
		{
			It.Weight /= TotalWeight;
		}
	}

	const FHazeCameraFinalizedWeightedFocusTargetInfo& opIndex(int32 Index) const
	{
		return Targets[Index];
	}

	FHazeCameraFinalizedWeightedFocusTargetInfo& opIndex(int32 Index)
	{
		return Targets[Index];
	}

	int Num() const
	{
		return Targets.Num();
	}

	FVector GetWeightedCenter()
    {
        if (Targets.Num() == 0)
		{
			devCheck(false);
            return FVector::ZeroVector;
		}

        // Use offsets from first position so we'll reduce precision errors
        FVector Origin = Targets[0].Location;
        FVector Offset = FVector::ZeroVector;
        float TotalWeight = Targets[0].Weight;
        for (int i = 1; i < Targets.Num(); i++)
        {
			const auto& Target = Targets[i];
            Offset += (Target.Location - Origin) * Target.Weight;
            TotalWeight += Target.Weight;
        }

        if (TotalWeight == 0.0)
            return FVector::ZeroVector;
    
        return Origin + Offset;
    }

	FHazeCameraFinalizedWeightedFocusTargetInfo& Last()
	{
		return Targets[Targets.Num() - 1];
	}

	bool GetFocusRotation(FVector From, FRotator& Out) const
	{
		FVector FocusOffset = FVector::ZeroVector;
	
		for(auto It : Targets)
		{
			FVector FocusLoc = It.Location;
			float Weight = It.Weight;
			FocusOffset += ((FocusLoc - From) * Weight);
		}

        if (!FocusOffset.IsNearlyZero())
		{
			Out = FocusOffset.ToOrientationRotator();
            return true;
		}

		return false;
	}

	bool GetFocusRotation(FVector From, FQuat& Out) const
	{
		FRotator FocusRotation;
		if (GetFocusRotation(From, FocusRotation))
		{
			Out = FocusRotation.Quaternion();
			return true;
		}

		return false;
	}

	FVector GetFocusLocation(FVector From) const
	{
		FVector FocusOffset = FVector::ZeroVector;
	
		for(auto It : Targets)
		{
			FVector FocusLoc = It.Location;
			float Weight = It.Weight;
			FocusOffset += ((FocusLoc - From) * Weight);
		}

		return From + FocusOffset;
	}
}


// The type used if no targets are added
enum ECameraWeightedTargetEmptyInitType
{
	DefaultToUser,
	DefaultToBothUsers,
	DefaultToBothPlayers,
}