enum ESolarFlareActivatableSwingPerchType
{
	PerchActivator,
	PoleActivator
}

class ASolarFlareActivatablePerchPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	ESolarFlareActivatableSwingPerchType Type;

	UPROPERTY(EditAnywhere)
	APerchPointActor Perch;

	UPROPERTY(EditAnywhere)
	APoleClimbActor Pole;

	UPROPERTY(EditAnywhere)
	ASolarFlareActivatableOpening Opener;

	UPROPERTY(EditAnywhere)
	ASolarFlareActivatablePump Pump;

	FVector PoleStartLoc;
	float PoleMoveSpeed = 300.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PoleStartLoc = Pole.ActorLocation;

		switch(Type)
		{
			case ESolarFlareActivatableSwingPerchType::PerchActivator:
				Pole.DisablePoleActor();
				Perch.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartedPerchingEvent");
				Perch.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingEvent");
				break;

			case ESolarFlareActivatableSwingPerchType::PoleActivator:
				for (AHazePlayerCharacter Player : Game::Players)
					Perch.PerchPointComp.DisableForPlayer(Player, this);
				Pole.OnStartPoleClimb.AddUFunction(this, n"OnStartPoleClimb");
				Pole.OnStopPoleClimb.AddUFunction(this, n"OnStopPoleClimb");
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Type == ESolarFlareActivatableSwingPerchType::PerchActivator)
		{
			if (Pole.bEnabled)
			{
				Pole.ActorLocation = Math::VInterpConstantTo(Pole.ActorLocation, PoleStartLoc - FVector(0,0,PoleMoveSpeed), DeltaSeconds, PoleMoveSpeed);
			}
			else
			{
				Pole.ActorLocation = Math::VInterpConstantTo(Pole.ActorLocation, PoleStartLoc, DeltaSeconds, PoleMoveSpeed);
			}
		}
	}

	UFUNCTION()
	private void OnStartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		Perch.PerchPointComp.EnableForPlayer(Player.OtherPlayer, this);
		
		if (Opener != nullptr)
			Opener.Open();
		if (Pump != nullptr)
			Pump.Open();
	}

	UFUNCTION()
	private void OnStopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		Perch.PerchPointComp.DisableForPlayer(Player.OtherPlayer, this);
		
		if (Opener != nullptr)
			Opener.Close();
		if (Pump != nullptr)
			Pump.Open();
	}

	UFUNCTION()
	private void OnPlayerStartedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		Pole.EnablePoleActor();
		
		if (Opener != nullptr)
			Opener.Close();
		if (Pump != nullptr)
			Pump.Open();
	}

	UFUNCTION()
	private void OnPlayerStoppedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		Pole.DisablePoleActor();

		if (Opener != nullptr)
			Opener.Open();
		if (Pump != nullptr)
			Pump.Open();
	}

	UFUNCTION()
	void PermaDisablePerchForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Perch.PerchPointComp.DisableForPlayer(Player, Instigator);
	}

	UFUNCTION()
	void PermaDisableSwingForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Pole.DisablePoleActor();
	}
};