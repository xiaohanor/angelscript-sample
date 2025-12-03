class USummitAdultDragonCircleStrafeManagerComponent : UBillboardComponent
{

}

enum ESummitAdultDragonCircleStrafeState
{
	Circling,
	AttackRun,
	NotStarted
}

class ASummitAdultDragonCircleStrafeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USummitAdultDragonCircleStrafeManagerComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitAdultDragonCircleStrafeManagerCirclingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitAdultDragonCircleStrafeManagerAttackRunCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitAdultDragonCircleStrafeManagerTempBossFacingPlayerCapability");

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent CirclingCamera;
	default CirclingCamera.RelativeLocation = FVector(3200, 0, 0);
	default CirclingCamera.RelativeRotation = FRotator(0, 180, 0);

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASplineActor SplineToFollow;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (ClampMin = 0))
	float SplineDistanceToStartAt = 0.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AStoneBossPeak Boss;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float CameraRotationSpeed = 10.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bTempBossRotation = false;

	ESummitAdultDragonCircleStrafeState CurrentState = ESummitAdultDragonCircleStrafeState::NotStarted;

	bool bStrafingIsFlipped = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorLocation(Boss.ActorLocation);
	}

	UFUNCTION(BlueprintCallable)
	void SetCircleStrafeState(ESummitAdultDragonCircleStrafeState NewState)
	{
		CurrentState = NewState;
	}

	UFUNCTION(BlueprintCallable)
	void SetStrafeDirection(bool bWantsFlipped)
	{
		bStrafingIsFlipped = bWantsFlipped;
	}

	void ActivateCirclingCamera(AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(CirclingCamera, 0.0, this, EHazeCameraPriority::High);
	}

	void DeactivateCirclingCamera(AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(CirclingCamera, 0.0);
	}

	UFUNCTION(BlueprintCallable)
	void SetAttackRunSpline(EHazeSelectPlayer PlayerSelect, ASplineActor AttackRunSpline)
	{
		TArray<AHazePlayerCharacter> Players;
		if(PlayerSelect == EHazeSelectPlayer::Mio)
		{
			Players.Add(Game::Mio);
		}
		else if (PlayerSelect == EHazeSelectPlayer::Zoe)
		{
			Players.Add(Game::Zoe);
		}
		else if (PlayerSelect == EHazeSelectPlayer::Both)
		{
			Players.Add(Game::Zoe);
			Players.Add(Game::Mio);
		}
		else 
		{
			return;
		}

		for(auto Player : Players)
		{
			auto SplineFollowManager = UAdultDragonSplineFollowManagerComponent::Get(Player);
			SplineFollowManager.SetSplineToFollow(AttackRunSpline);
		}
	}
};

#if EDITOR
class USummitAdultDragonCircleStrafeManagerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitAdultDragonCircleStrafeManagerComponent;

	float MovingSplinePosDistance = 0.0;
	float LastTimeStamp = 0.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitAdultDragonCircleStrafeManagerComponent>(Component);
		if(!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;

		auto CircleStrafeManager = Cast<ASummitAdultDragonCircleStrafeManager>(Comp.Owner);
		if(CircleStrafeManager == nullptr)
			return;
		
		// if(CircleStrafeManager.CirclingCamera != nullptr)
		// {
		// 	DrawStartPoint(CircleStrafeManager);
		// 	DrawMovingPoint(CircleStrafeManager);
		// }
	}

	private void DrawStartPoint(ASummitAdultDragonCircleStrafeManager StrafeManager)
	{
		auto SplineComp = StrafeManager.SplineToFollow.Spline;
		float ClampedSplineDistance = Math::Clamp(StrafeManager.SplineDistanceToStartAt, 0.0, SplineComp.SplineLength);
		auto SplinePos = SplineComp.GetSplinePositionAtSplineDistance(ClampedSplineDistance);

		SetRenderForeground(false);
		DrawWireSphere(SplinePos.WorldLocation, 400, FLinearColor::Red, 20);
	}

	private void DrawMovingPoint(ASummitAdultDragonCircleStrafeManager StrafeManager)
	{
		float TimeStamp = Time::GameTimeSeconds;
		float DeltaTime = TimeStamp - LastTimeStamp;
		LastTimeStamp = TimeStamp;

		auto SplineComp = StrafeManager.SplineToFollow.Spline;

		MovingSplinePosDistance += StrafeManager.CameraRotationSpeed * DeltaTime;
		MovingSplinePosDistance %= SplineComp.SplineLength;

		auto SplinePos = SplineComp.GetSplinePositionAtSplineDistance(MovingSplinePosDistance);

		SetRenderForeground(false);
		DrawWireSphere(SplinePos.WorldLocation, 400, FLinearColor::Green, 20);
	}
}
#endif