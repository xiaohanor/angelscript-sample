UCLASS(Abstract)
class ASketchbook_Scale : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(EditAnywhere)
	ASketchbook_Scale OtherScale;

	AHazePlayerCharacter Zoe;
	AHazePlayerCharacter Mio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"ImpactPlayer");
		ImpactComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"ImpactPlayerEnded");
	}

	UFUNCTION()
	private void ImpactPlayer(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
		{
			Zoe = Player;
			Print("ZOE");
		}

		if(Player.IsMio())
			Mio = Player;
	}

	UFUNCTION()
	private void ImpactPlayerEnded(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
			Zoe = nullptr;

		if(Player.IsMio())
			Mio = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(IsValid(Zoe))
		{
			TranslateComp.ApplyForce(Zoe.GetActorLocation(),ActorUpVector*-100);
			if(IsValid(OtherScale))
				OtherScale.TranslateComp.ApplyForce(Zoe.GetActorLocation(),ActorUpVector*100);
		}
		if(IsValid(Mio))
		{
			TranslateComp.ApplyForce(ActorLocation,ActorUpVector*-100);
			if(IsValid(OtherScale))
				OtherScale.TranslateComp.ApplyForce(ActorLocation,ActorUpVector*100);
		}
	}
};