
UCLASS(Abstract)
class USpotSoundModeComponent : UHazeSpotSoundModeComponent
{
	UPROPERTY()
	USpotSoundComponent SpotComponent = nullptr;
	// default ParentSpot = Cast<USpotSoundComponent>(GetAttachParent());

	USpotSoundComponent GetParentSpot() property
	{
		if (SpotComponent != nullptr)
			return SpotComponent;

		SpotComponent = Cast<USpotSoundComponent>(GetAttachParent());
		return SpotComponent;
	}

	TSoftObjectPtr<AActor> GetActorDependency() property
	{
		return ParentSpot.LinkedMeshOwner;
	}

	FSoundDefReference GetSpotSoundDefData() property
	{
		return ParentSpot.AssetData.SoundDefAsset;
	}

	#if EDITOR
	void OnModeAdded(USpotSoundComponent Spot) {}
	void OnModeRemoved(USpotSoundComponent Spot) {}
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Notify parent of existiance of modecomponent
		auto Parent = ParentSpot;
		if (Parent != nullptr)
		{
			Parent.ModeComponent = this;
			Parent.SetPendingActor(ActorDependency);
			Parent.ModeComponentStart();
		}
	}

	void Start() {}
	void Stop() {}

	void SetupMode() {}

	void TickMode(float DeltaSeconds) {}
}