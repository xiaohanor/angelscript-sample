class UCoastContainerTurretFallCapability : UHazeCapability
{
	UCoastContainerTurretFallComponent FallComp;
	UCoastContainerTurretDoorComponent TurretDoorComp;

	float MoveAlpha;
	float MoveSpeed = 2;
	float OpenTime;
	FHazeAcceleratedFloat SpeedAcc;
	bool bLanded;

	FVector StartLocation;
	FVector EndLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FallComp = UCoastContainerTurretFallComponent::GetOrCreate(Owner);
		TurretDoorComp = UCoastContainerTurretDoorComponent::GetOrCreate(Owner);

		StartLocation = Owner.ActorRelativeLocation + Owner.ActorUpVector * 3000;
		EndLocation = Owner.ActorRelativeLocation;

		Owner.ActorRelativeLocation = StartLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FallComp.bFall)
			return false;
		if(FallComp.bFell)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(OpenTime != 0 && Time::GetGameTimeSince(OpenTime) > FallComp.OpenDelay)
			return true;
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FallComp.StartFall();
		UCoastContainerTurretEffectHandler::Trigger_OnFallStart(Owner);
		OpenTime = 0;
		bLanded = false;
		MoveAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FallComp.bFell = true;
		TurretDoorComp.Open();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveAlpha < 1)
			Move(DeltaTime);
		else if(!bLanded)
		{
			bLanded = true;
			OpenTime = Time::GameTimeSeconds;
			UCoastContainerTurretEffectHandler::Trigger_OnFallEnd(Owner);
			UCoastContainerTurretEffectHandler::Trigger_OnLand(Owner);
			for(AHazePlayerCharacter Player: Game::Players)
			{
				Player.PlayCameraShake(FallComp.LandCameraShake, this);
				Player.PlayForceFeedback(FallComp.LandForceFeedback, false, false, this);
			}
		}
	}

	private void Move(float DeltaTime)
	{
		SpeedAcc.AccelerateTo(MoveSpeed, 1, DeltaTime);
		MoveAlpha = Math::Clamp(MoveAlpha + DeltaTime * SpeedAcc.Value, 0, 1);
		Owner.ActorRelativeLocation = Math::Lerp(StartLocation, EndLocation, MoveAlpha);
	}
}