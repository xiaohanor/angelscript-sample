enum ESmallCrabState
{
	Idle,
	Flee,
	Hide
}

UCLASS(Abstract)
class ASketchBookSmallCrab : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent,Attach = Root)
	UHazeCharacterSkeletalMeshComponent SkelMesh;

	FVector OriginLocation;

	ESmallCrabState CrabState;

	AHazePlayerCharacter CurrentPlayer;

	UPROPERTY(EditAnywhere)
	float OffsetDuration = 0;
	
	bool bDespawn;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveAwayLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ActorLocation.Distance(OriginLocation) > 300)
			CrabState = ESmallCrabState::Hide;
		else if(Game::GetClosestPlayer(GetActorLocation()).GetDistanceTo(this) < 400)
		{
			if(CurrentPlayer == nullptr)
				CurrentPlayer = Game::GetClosestPlayer(GetActorLocation());

			CrabState = ESmallCrabState::Flee;
		}

		if(CurrentPlayer != nullptr && CurrentPlayer.ActorLocation.Distance(ActorLocation) > 600)
		{
			CurrentPlayer = nullptr;
			CrabState = ESmallCrabState::Idle;
		}

		if(CrabState == ESmallCrabState::Idle)
		{
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(),GetActorLocation() + (ActorRightVector * Math::Sin(Time::GameTimeSeconds + OffsetDuration) * -1),DeltaSeconds,100));
			SetActorRotation(Math::RInterpConstantTo(GetActorRotation(),FRotator(0,GetActorRotation().Yaw+(Math::Sin(Time::GameTimeSeconds) * 1),0),DeltaSeconds,10));
		}

		if(CrabState == ESmallCrabState::Flee && CurrentPlayer != nullptr)
		{
			MoveAwayLocation.SetWorldLocation(CurrentPlayer.GetActorLocation());
			FVector MoveAwayVector = MoveAwayLocation.RelativeLocation;
			MoveAwayVector.Normalize();
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(),GetActorLocation() + (ActorRightVector * MoveAwayVector.Y * -10),DeltaSeconds,600 - Math::Abs(MoveAwayLocation.RelativeLocation.Y)));
			SetActorRotation(Math::RInterpConstantTo(GetActorRotation(),FRotator(0,GetActorRotation().Yaw+(MoveAwayVector.Y * 20),0),DeltaSeconds,10));
		}
		if(CrabState == ESmallCrabState::Hide)
		{
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(),GetActorLocation() + (ActorUpVector*-10),DeltaSeconds,300));
			USketchbookSmallCrabEventHandler::Trigger_HideEvent(this);
			if(!bDespawn)
			{
				Timer::SetTimer(this,n"StopTickTimer",1,false,0,0);
				bDespawn = true;
			}
		}
	}

	UFUNCTION()
	private void StopTickTimer()
	{
		SetActorTickEnabled(false);
		Timer::SetTimer(this,n"Respawn",5,false,0,0);
	}

	UFUNCTION()
	private void Respawn()
	{
		if(OriginLocation.Distance(Game::GetClosestPlayer(OriginLocation).ActorLocation) > 1000)
		{
			SetActorLocation(OriginLocation);
			CrabState = ESmallCrabState::Idle;
			USketchbookSmallCrabEventHandler::Trigger_HideEvent(this);
			SetActorTickEnabled(true);
			bDespawn = false;
			CurrentPlayer = nullptr;
		}
		else
			Timer::SetTimer(this,n"Respawn",5,false,0,0);
	}
};
