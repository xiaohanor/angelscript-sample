class AMaxSecurityLaserHellLaserAlarm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh3;

	UPROPERTY(DefaultComponent, Attach = Mesh1)
	UNiagaraComponent Laser1;
	default Laser1.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Mesh2)
	UNiagaraComponent Laser2;
	default Laser1.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Mesh3)
	UNiagaraComponent Laser3;
	default Laser1.bAutoActivate = false;

	TArray<UNiagaraComponent> Lasers;

	UPROPERTY(EditInstanceOnly)
	bool bDebug = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Lasers.Add(Laser1);
		Lasers.Add(Laser2);
		Lasers.Add(Laser3);

		SetMeshColor(FLinearColor::White);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bDebug)
			return;

		for(auto Player : Game::Players)
		{
			//PrintToScreen("Dot: " + Dot);
		}
	}

	void SetMeshColor(FLinearColor Color)
	{
		Mesh1.SetColorParameterValueOnMaterialIndex(0, n"Global_EmissiveTint", Color);
		Mesh2.SetColorParameterValueOnMaterialIndex(0, n"Global_EmissiveTint", Color);
		Mesh3.SetColorParameterValueOnMaterialIndex(0, n"Global_EmissiveTint", Color);
	}

	// If player is nullptr, we kill the closest player
	UFUNCTION(CrumbFunction)
	AHazePlayerCharacter CrumbShootLaser(AHazePlayerCharacter Player)
	{
		AHazePlayerCharacter TargetPlayer;

		if(Player == nullptr)
		{
			float LowestDot = BIG_NUMBER;
			int Index = -1;

			for(int i = 0; i < Game::Players.Num(); i++)
			{
				float Dot = Math::Abs((Game::Players[i].ActorLocation - ActorLocation).DotProduct(ActorUpVector));
				if(Dot < LowestDot)
				{
					LowestDot = Dot;
					Index = i;
				}
			}

			TargetPlayer = Game::Players[Index];
		}
		else
		{
			TargetPlayer = Player;
		}

		for(auto Laser : Lasers)
		{
			FVector Dir = TargetPlayer.ActorLocation - Laser.WorldLocation;
			float Length = Dir.Size();
			Laser.SetWorldRotation(FRotator::MakeFromXZ(Dir, FVector::UpVector));
			Laser.SetVectorParameter(n"BeamEnd", FVector(Length, 1.0, 1.0));
			Laser.Activate(true);
		}

		FLaserHellLaserAlarmEventData Data;
		Data.LaserAlarmActor = this;
		UMaxSecurityLaserHellEventHandler::Trigger_LaserShot(this, Data);

		return TargetPlayer;
	}
};