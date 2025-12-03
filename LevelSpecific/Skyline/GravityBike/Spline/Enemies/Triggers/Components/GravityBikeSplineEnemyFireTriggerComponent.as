UCLASS(NotBlueprintable)
class UGravityBikeSplineEnemyFireTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{	
	access Internal = private, UGravityBikeSplineEnemyFireTriggerComponentVisualizer;

	default StartColor = ColorDebug::Red;
	default EndColor = ColorDebug::Amethyst;

	UPROPERTY(EditAnywhere, Category = "Enemy Fire Component")
	EGravityBikeSplineEnemyFireType FireType = EGravityBikeSplineEnemyFireType::Missile;

	UPROPERTY(EditAnywhere, Category = "Enemy Fire Component|Missile", Meta = (EditCondition = "FireType == EGravityBikeSplineEnemyFireType::Missile"))
	access:Internal
	bool bFireInComponentDirection = true;

	UPROPERTY(EditAnywhere, Category = "Enemy Fire Component|Missile", Meta = (EditCondition = "FireType == EGravityBikeSplineEnemyFireType::Missile"))
	const FGravityBikeSplineEnemyMissileSettings MissileSettings;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Enemy Fire Component|Missile", Meta = (EditCondition = "FireType == EGravityBikeSplineEnemyFireType::Missile"))
	bool bVisualizeMissilePath = true;

	UPROPERTY(EditInstanceOnly, Category = "Enemy Fire Component|Missile", Meta = (EditCondition = "FireType == EGravityBikeSplineEnemyFireType::Missile && bVisualizeMissilePath", EditConditionHides))
	TSoftObjectPtr<AGravityBikeSplineActor> PlayerSpline;

	UPROPERTY(EditInstanceOnly, Category = "Enemy Fire Component|Missile", Meta = (EditCondition = "FireType == EGravityBikeSplineEnemyFireType::Missile && bVisualizeMissilePath", EditConditionHides))
	bool bAccountForPlayerSpeed = true;

	UPROPERTY(EditInstanceOnly, Category = "Enemy Fire Component|Missile", Meta = (EditCondition = "FireType == EGravityBikeSplineEnemyFireType::Missile && bVisualizeMissilePath", EditConditionHides))
	FVector PlayerRelativeOffset = FVector(0, 0, 150);

	UPROPERTY(EditInstanceOnly, Category = "Enemy Fire Component|Missile", Meta = (EditCondition = "FireType == EGravityBikeSplineEnemyFireType::Missile && bVisualizeMissilePath", EditConditionHides))
	TSoftObjectPtr<AGravityBikeSplineEnemy> EnemyOnSpline;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(FireType == EGravityBikeSplineEnemyFireType::Missile)
			bImplementsExit = false;
	}

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		switch(FireType)
		{
			case EGravityBikeSplineEnemyFireType::Missile:
			{
				// Don't fire missiles on teleports
				if(bIsTeleport)
					return;

				auto LauncherComp = UGravityBikeSplineEnemyMissileLauncherComponent::Get(TriggerUserComp.Owner);
				if(LauncherComp != nullptr)
					LauncherComp.FireInstigators.Add(this);
				break;
			}

			case EGravityBikeSplineEnemyFireType::Rifle:
			{
				auto CarEnemy = Cast<AGravityBikeSplineCarEnemy>(TriggerUserComp.Owner);
				if(CarEnemy != nullptr)
				{
					CarEnemy.TurretComp.FireInstigators.Add(this);
					break;
				}

				auto BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(TriggerUserComp.Owner);
				if(BikeEnemy != nullptr)
				{
					if(BikeEnemy.Passenger != nullptr)
					{
						auto PistolComp = UGravityBikeSplineBikeEnemyDriverPistolComponent::Get(BikeEnemy.Passenger);
						if(PistolComp != nullptr)
						{
							PistolComp.FireInstigators.Add(this);
							break;
						}
					}
				}
				break;
			}
		}
	}

	void OnEnemyExit(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		switch(FireType)
		{
			case EGravityBikeSplineEnemyFireType::Missile:
				break;

			case EGravityBikeSplineEnemyFireType::Rifle:
			{
				auto CarEnemy = Cast<AGravityBikeSplineCarEnemy>(TriggerUserComp.Owner);
				if(CarEnemy != nullptr)
				{
					CarEnemy.TurretComp.FireInstigators.Remove(this);
					break;
				}

				auto BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(TriggerUserComp.Owner);
				if(BikeEnemy != nullptr)
				{
					if(BikeEnemy.Passenger != nullptr)
					{
						auto PistolComp = UGravityBikeSplineBikeEnemyDriverPistolComponent::Get(BikeEnemy.Passenger);
						if(PistolComp != nullptr)
						{
							PistolComp.FireInstigators.Remove(this);
							break;
						}
					}
				}
				break;
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "Enemy Fire Component")
	private void SnapRotationToSpline()
	{
		const FQuat Rotation = GetSplineComp().GetClosestSplineWorldRotationToWorldLocation(WorldLocation);
		SetWorldRotation(Rotation);
	}

	FVector GetFireDirection() const
	{
		if(bFireInComponentDirection)
			return ForwardVector;
		else
			return FVector::ZeroVector;
	}

#if EDITOR
	FString GetDebugString() const override
	{
		return Super::GetDebugString() + f", {FireTypeToString()}";
	}

	FString FireTypeToString() const
	{
		switch(FireType)
		{
			case EGravityBikeSplineEnemyFireType::Missile:
				return "Missile";

			case EGravityBikeSplineEnemyFireType::Rifle:
				return "Rifle";
		}
	}
#endif
};

#if EDITOR
class UGravityBikeSplineEnemyFireTriggerComponentVisualizer : UGravityBikeSplineEnemyTriggerComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineEnemyFireTriggerComponent;
	
	void Visualize(const UGravityBikeSplineDistanceTriggerComponent InTriggerComp) override
	{
		Super::Visualize(InTriggerComp);

		auto EnemyFireTriggerComp = Cast<UGravityBikeSplineEnemyFireTriggerComponent>(InTriggerComp);
		if(EnemyFireTriggerComp == nullptr)
			return;

		const FTransform StartTransform = EnemyFireTriggerComp.GetSplineComp().GetWorldTransformAtSplineDistance(EnemyFireTriggerComp.GetStartDistance());

		if(EnemyFireTriggerComp.FireType == EGravityBikeSplineEnemyFireType::Missile)
		{
			if(EnemyFireTriggerComp.bFireInComponentDirection)
				DrawArrow(StartTransform.Location, StartTransform.Location + EnemyFireTriggerComp.ForwardVector * 1000, FLinearColor::Red, 100, 10, true);

			if(EnemyFireTriggerComp.bVisualizeMissilePath && EnemyFireTriggerComp.PlayerSpline.IsValid() && Editor::IsComponentSelected(EnemyFireTriggerComp))
			{
				float PlayerMoveSpeed = Cast<UGravityBikeSplineSettings>(UGravityBikeSplineSettings.DefaultObject).MaxSpeed;
				const FVector InitialDirection = EnemyFireTriggerComp.bFireInComponentDirection ? EnemyFireTriggerComp.ForwardVector : StartTransform.Rotation.ForwardVector;

				GravityBikeSplineEnemyFireTriggerComponent::VisualizeMissilePath(this, EnemyFireTriggerComp, PlayerMoveSpeed, InitialDirection, EnemyFireTriggerComp.MissileSettings);
			}
		}
	}
};
#endif

#if EDITOR
namespace GravityBikeSplineEnemyFireTriggerComponent
{
	void VisualizeMissilePath(const UHazeScriptComponentVisualizer Visualizer, const UGravityBikeSplineEnemyFireTriggerComponent FireComp, float PlayerSpeed, FVector InitialDirection, FGravityBikeSplineEnemyMissileSettings MissileSettings)
	{
		const float DeltaTime = 0.02;
		const float SimulateDuration = MissileSettings.FlyStraightTime * 10;
		const float TargetRadius = 500;

		float Time = 0;
		EGravityBikeSplineEnemyMissileState State = EGravityBikeSplineEnemyMissileState::FlyStraight;
		FVector WorldLocation;
		FQuat WorldRotation;

		FTransform InitialTransform(FQuat::MakeFromXZ(InitialDirection, FireComp.UpVector), FireComp.WorldLocation);
		float InitialPlayerDistanceAlongSpline = FireComp.PlayerSpline.Get().SplineComp.GetClosestSplineDistanceToWorldLocation(FireComp.WorldLocation);

		if(FireComp.EnemyOnSpline.IsValid())
		{
			auto MoveComp = UGravityBikeSplineEnemyMovementComponent::Get(FireComp.EnemyOnSpline.Get());
			if(MoveComp != nullptr)
			{
				FVector NoLeadAmountSplineLocation = FireComp.PlayerSpline.Get().SplineComp.GetWorldLocationAtSplineDistance(InitialPlayerDistanceAlongSpline);
				Visualizer.DrawWireSphere(NoLeadAmountSplineLocation, TargetRadius, FLinearColor::Gray, 2, 8, true);
				InitialPlayerDistanceAlongSpline -= MoveComp.LeadAmount;
				FVector LeadAmountSplineLocation = FireComp.PlayerSpline.Get().SplineComp.GetWorldLocationAtSplineDistance(InitialPlayerDistanceAlongSpline);
				Visualizer.DrawArrow(NoLeadAmountSplineLocation, LeadAmountSplineLocation, FLinearColor::Gray, 100,2, true);
				Visualizer.DrawWorldString(f"Lead Amount: {Math::RoundToInt(MoveComp.LeadAmount)}", Math::Lerp(NoLeadAmountSplineLocation, LeadAmountSplineLocation, 0.5), FLinearColor::Gray);
			}
		}

		FTransform SplineTransform = FireComp.PlayerSpline.Get().SplineComp.GetWorldTransformAtSplineDistance(InitialPlayerDistanceAlongSpline);

		FGravityBikeSplineEnemyMissileRelativeMovementData SimulationData(
			InitialTransform,
			SplineTransform,
			MissileSettings.FlyStraightMoveSpeed
		);

		float PointTime = Time::GameTimeSeconds % SimulateDuration;
		bool bHasDrawnPoint = false;
		
		FVector InitialTargetWorldLocation = SplineTransform.TransformPositionNoScale(FireComp.PlayerRelativeOffset);
		Visualizer.DrawWireSphere(InitialTargetWorldLocation, TargetRadius, FLinearColor::Green, 2, 8, true);
		Visualizer.DrawArrow(SplineTransform.Location, InitialTargetWorldLocation, FLinearColor::Green, 20, 2, true);

		bool bHit = false;

		WorldLocation = InitialTransform.Location;
		WorldRotation = InitialTransform.Rotation;

		while(Time < SimulateDuration)
		{
			SimulationData.Prepare(WorldLocation, WorldRotation, NAME_None);

			float PlayerDistanceAlongSpline = InitialPlayerDistanceAlongSpline;
			if(FireComp.bAccountForPlayerSpeed)
				PlayerDistanceAlongSpline += (Time * PlayerSpeed);

			SplineTransform = FireComp.PlayerSpline.Get().SplineComp.GetWorldTransformAtSplineDistance(PlayerDistanceAlongSpline);

			FVector TargetWorldLocation = SplineTransform.TransformPositionNoScale(FireComp.PlayerRelativeOffset);

			switch(State)
			{
				case EGravityBikeSplineEnemyMissileState::FlyStraight:
				{
					SimulationData.TickFlyStraight(SplineTransform.Location, MissileSettings.FlyStraightMoveSpeed, DeltaTime);

					if(Time > MissileSettings.FlyStraightTime)
					{
						State = EGravityBikeSplineEnemyMissileState::TurnAround;
						DrawStateChangeString(Visualizer, WorldLocation, EGravityBikeSplineEnemyMissileState::FlyStraight);
					}

					break;
				}

				case EGravityBikeSplineEnemyMissileState::TurnAround:
				{
					const FVector TargetWorldDirection = (TargetWorldLocation - WorldLocation).GetSafeNormal();
					bool bFinished = SimulationData.TickTurnAround(SplineTransform.Location, MissileSettings.TurnAroundMoveSpeed, MissileSettings.TurnAroundTurnSpeed, DeltaTime, TargetWorldDirection);

					if(bFinished)
					{
						State = EGravityBikeSplineEnemyMissileState::Homing;
						DrawStateChangeString(Visualizer, WorldLocation, EGravityBikeSplineEnemyMissileState::TurnAround);
					}

					break;
				}

				case EGravityBikeSplineEnemyMissileState::Homing:
				{
					SimulationData.TickHoming(SplineTransform.Location, MissileSettings.HomingMoveSpeed, MissileSettings.HomingTurnSpeed, DeltaTime, TargetWorldLocation);

					if(WorldLocation.Equals(TargetWorldLocation, TargetRadius))
					{
						DrawStateChangeString(Visualizer, WorldLocation, EGravityBikeSplineEnemyMissileState::Homing);
						bHit = true;
						break;
					}

					break;
				}

				case EGravityBikeSplineEnemyMissileState::Dropped:
					break;
			}

			if(bHit)
				break;

			WorldLocation = SimulationData.WorldLocation;
			WorldRotation = SimulationData.WorldRotation;

			Visualizer.DrawLine(SimulationData.PreviousLocation, WorldLocation, ColorFromState(State), 5, true);

			Time += DeltaTime;

			if(!bHasDrawnPoint && PointTime < Time)
			{
				bHasDrawnPoint = true;
				const float Length = 1000;
				Visualizer.DrawArrow(WorldLocation, WorldLocation + WorldRotation.ForwardVector * Length, FLinearColor::White, 100, 10, true);
				Visualizer.DrawWorldString(f"Speed: {Math::RoundToInt(SimulationData.AccMoveSpeed.Value)} \n", WorldLocation, FLinearColor::White, 1.5);

				if(FireComp.bAccountForPlayerSpeed)
					Visualizer.DrawWireSphere(TargetWorldLocation, TargetRadius, FLinearColor::Yellow, 2, 8, true);
			}
		}

		if(bHit)
		{
			FVector HitTargetWorldLocation = SplineTransform.TransformPositionNoScale(FireComp.PlayerRelativeOffset);
			Visualizer.DrawWireSphere(HitTargetWorldLocation, TargetRadius, FLinearColor::Red, 2, 8, true);
		}

		if(FireComp.bAccountForPlayerSpeed)
		{
			SplineTransform = FireComp.PlayerSpline.Get().SplineComp.GetWorldTransformAtSplineDistance(InitialPlayerDistanceAlongSpline + PlayerSpeed * SimulateDuration);
			FVector FinalTargetWorldLocation = SplineTransform.TransformPositionNoScale(FireComp.PlayerRelativeOffset);
			Visualizer.DrawWireSphere(FinalTargetWorldLocation, TargetRadius, FLinearColor::Black, 2, 8, true);
			Visualizer.DrawArrow(SplineTransform.Location, FinalTargetWorldLocation, FLinearColor::Black, 20, 2, true);
		}
	}

	FLinearColor ColorFromState(EGravityBikeSplineEnemyMissileState State)
	{
		switch(State)
		{
			case EGravityBikeSplineEnemyMissileState::FlyStraight:
				return FLinearColor::Green;

			case EGravityBikeSplineEnemyMissileState::TurnAround:
				return FLinearColor::Yellow;

			case EGravityBikeSplineEnemyMissileState::Homing:
				return FLinearColor::Red;

			case EGravityBikeSplineEnemyMissileState::Dropped:
				return FLinearColor::LucBlue;
		}
	}

	void DrawStateChangeString(const UHazeScriptComponentVisualizer Visualizer, FVector WorldLocation, EGravityBikeSplineEnemyMissileState State)
	{
		FLinearColor Color = ColorFromState(State);

		FString StateName;
		switch(State)
		{
			case EGravityBikeSplineEnemyMissileState::FlyStraight:
				StateName = "Fly Straight";
				break;

			case EGravityBikeSplineEnemyMissileState::TurnAround:
				StateName = "Turn Around";
				break;

			case EGravityBikeSplineEnemyMissileState::Homing:
				StateName = "Homing";
				break;
				
			case EGravityBikeSplineEnemyMissileState::Dropped:
				StateName = "Dropped";
				break;
		}

		Visualizer.DrawWorldString(StateName, WorldLocation, Color);
	}
};
#endif