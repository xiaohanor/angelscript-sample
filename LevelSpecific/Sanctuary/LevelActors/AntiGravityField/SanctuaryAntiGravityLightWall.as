class ASanctuaryAntiGravityLightWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryAntiGravityField AntiGravityField;

	bool bIsInsideRadius = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetInsideRadius(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ActorLocation.Distance(AntiGravityField.ActorLocation) < AntiGravityField.OverlapperField.BoundsRadius 
			&& !bIsInsideRadius)
		{
			SetInsideRadius(true);
		}
		
		if (ActorLocation.Distance(AntiGravityField.ActorLocation) > AntiGravityField.OverlapperField.BoundsRadius 
			&& bIsInsideRadius)
		{
			SetInsideRadius(false);
		}
	}

	UFUNCTION()
	private void HandlePlayerToggleInsideGravityField(AHazePlayerCharacter Player, bool bInField)
	{
	}

	private void SetInsideRadius(bool bInsideRadius)
	{
		bIsInsideRadius = bInsideRadius;
		SetActorEnableCollision(bInsideRadius);
	}
};