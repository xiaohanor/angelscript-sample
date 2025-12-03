event void FCentipedeAttachedToSwingPoint();
event void FCentipedeReleasedSwingPoint();

UCLASS(Abstract)
class UCentipedeSwingPointEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCentipedeAttached() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCentipedeDetached() {}
}

class ACentipedeSwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Mesh, ShowOnActor)
	UCentipedeSwingPointComponent SwingPointComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;

	ACentipedeRotatingSwingBase RotatingSwingBase;

	UPROPERTY()
	FCentipedeAttachedToSwingPoint OnCentipedeAttached;

	UPROPERTY()
	FCentipedeReleasedSwingPoint OnCentipedeReleased;

	FVector GetSwingPlaneVector() const property
	{
		return SwingPointComponent.SwingPlaneVector;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotatingSwingBase = Cast<ACentipedeRotatingSwingBase>(AttachParentActor);

		if (RotatingSwingBase != nullptr)
		{
			RotatingSwingBase.SetJumpToEnabled.AddUFunction(this, n"SetJumpToEnabled");
			OnCentipedeAttached.AddUFunction(RotatingSwingBase, n"CentipedeAttached");
			
			//UPlayerCentipedeSwingComponent::GetOrCreate(Game::Zoe).OnSwingPointReleased.AddUFunction(RotatingSwingBase, n"HandleSwingReleased");
			//UPlayerCentipedeSwingComponent::GetOrCreate(Game::Mio).OnSwingPointReleased.AddUFunction(RotatingSwingBase, n"HandleSwingReleased");
		}

		UPlayerCentipedeSwingComponent::GetOrCreate(Game::Zoe).OnSwingStart.AddUFunction(this, n"HandleSwingStart");
		UPlayerCentipedeSwingComponent::GetOrCreate(Game::Mio).OnSwingStart.AddUFunction(this, n"HandleSwingStart");
		UPlayerCentipedeSwingComponent::GetOrCreate(Game::Zoe).OnSwingPointReleased.AddUFunction(this, n"HandleSwingReleased");
		UPlayerCentipedeSwingComponent::GetOrCreate(Game::Mio).OnSwingPointReleased.AddUFunction(this, n"HandleSwingReleased");
	}

	UFUNCTION()
	private void HandleSwingStart(AHazePlayerCharacter Player, ECentipedePlayerSwingRole SwingRole,
	                              UCentipedeSwingPointComponent SwingPoint)
	{
		if (SwingPoint == SwingPointComponent && SwingRole == ECentipedePlayerSwingRole::Biter)
		{
			OnCentipedeAttached.Broadcast();
			UCentipedeSwingPointEventHandler::Trigger_OnCentipedeAttached(this);
		}
	}

	UFUNCTION()
	private void HandleSwingReleased(AHazePlayerCharacter Player,
	                                 UCentipedeSwingPointComponent SwingPoint)
	{
		if (SwingPoint == SwingPointComponent)
		{
			OnCentipedeReleased.Broadcast();
			UCentipedeSwingPointEventHandler::Trigger_OnCentipedeDetached(this);
		}
	}

	UFUNCTION()
	void SetJumpToEnabled(bool bEnabled)
	{
		SwingPointComponent.bJumpAutoTargeting = bEnabled;
	}
}