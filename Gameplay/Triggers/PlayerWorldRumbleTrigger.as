
struct FPlayerWorldRumbleIndex
{
	bool bIsActive = false;
	UCameraShakeBase CameraShake;
}

/**
 * A component that lets you define a camera shake and a force feedback 
 * that will trigger when the player is in range
 */
class UPlayerWorldRumbleTrigger : UHazeMovablePlayerTriggerComponent
{
	UPROPERTY(EditAnywhere, Category = "Force Feedback", Meta =(ShowOnlyInnerProperties))
	FHazeFrameForceFeedback ForceFeedBack;
	default ForceFeedBack.LeftMotor = 0;
	default ForceFeedBack.RightMotor = 0;
	
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	ECameraShakePlaySpace CameraShakeSpace = ECameraShakePlaySpace::World;

	/** If you want to modify the strength based on the distance from this components center 
	 * @Time; (0, 1) The distance percentage to the center where 0 is at the components center 
	*/
	UPROPERTY(EditAnywhere, Category = "Intensity")
	FRuntimeFloatCurve DistanceShakeScale;
	default DistanceShakeScale.AddDefaultKey(0.0, 1.0);
	default DistanceShakeScale.AddDefaultKey(1.0, 0.0);
	
	/** Should the distance to the epi center include horizontal plane
	 * (if not, only the vertical distance will be used)
	 */
	UPROPERTY(EditAnywhere, Category = "Intensity")
	bool bGetDistanceInHorizontalPlane = true;

	/** Should the distance to the epi center include vertical plane
	 * (if not, only the horizontal distance will be used)
	 */
	UPROPERTY(EditAnywhere, Category = "Intensity")
	bool bGetDistanceInVerticalPlane = true;


	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		if(!CameraShakeClass.IsValid())
			return;

		auto Container = UWorldRumbleContainerComponent::GetOrCreate(Player);
		Container.Rumbles.FindOrAdd(this).bIsActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		if(!CameraShakeClass.IsValid())
			return;

		auto Container = UWorldRumbleContainerComponent::GetOrCreate(Player);
		Container.Rumbles.FindOrAdd(this).bIsActive = false;
	}

	float GetIntensity(AHazePlayerCharacter Player) const
	{
		if(!bGetDistanceInHorizontalPlane && !bGetDistanceInVerticalPlane)
			return 1;

		float MaxDistance = Shape.GetEncapsulatingSphereRadius();
		float Distance = 0;
		if(bGetDistanceInHorizontalPlane && bGetDistanceInVerticalPlane)
			Distance = Player.FocusLocation.Distance(WorldLocation);
		else if(bGetDistanceInHorizontalPlane)
			Distance = (Player.FocusLocation - WorldLocation).VectorPlaneProject(Player.MovementWorldUp).Size();
		else
			Distance = (Player.FocusLocation - WorldLocation).ProjectOnToNormal(Player.MovementWorldUp).Size();

		float DefaultAlpha = Math::Min(Distance / MaxDistance, 1);
		return DistanceShakeScale.GetFloatValue(DefaultAlpha, DefaultAlpha);
	}
}

UCLASS(NotPlaceable)
class UWorldRumbleContainerComponent : UActorComponent
{
	TMap<UPlayerWorldRumbleTrigger, FPlayerWorldRumbleIndex> Rumbles;
}


class UWorldRumbleUpdateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraModifiers);
	
	default TickGroup = EHazeTickGroup::Gameplay;

	UWorldRumbleContainerComponent Container;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Container = UWorldRumbleContainerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Container.Rumbles.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Container.Rumbles.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Container.Rumbles.Remove(nullptr);
		for(auto It : Container.Rumbles)
		{
			const auto& Index = It.Value;
			if(Index.bIsActive)
			{
				float Intensity = It.Key.GetIntensity(Player);
				if(Index.CameraShake == nullptr)
				{
					It.Value.CameraShake = Player.PlayCameraShake(It.Key.CameraShakeClass, this, Intensity, It.Key.CameraShakeSpace);
				}

				Player.SetFrameForceFeedback(It.Key.ForceFeedBack, Intensity);
			}
			else
			{
				if(Index.CameraShake != nullptr)
				{
					Player.StopCameraShakeByInstigator(this);
					It.Value.CameraShake = nullptr;
				}
			}
		}
	}
};