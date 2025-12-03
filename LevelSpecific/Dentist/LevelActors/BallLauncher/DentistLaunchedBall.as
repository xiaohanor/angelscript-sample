#if !RELEASE
namespace DevTogglesDentist
{
	const FHazeDevToggleBool PrintLaunchedBallRollEvents;
	const FHazeDevToggleBool PrintLaunchedBallFallEvents;
};
#endif

event void FDentistLaunchedBallStartMoving();
event void FDentistLaunchedBallHitWater();

UCLASS(Abstract, HideCategories = "Activation Navigation Actor LevelInstance Debug Cooking")
class ADentistLaunchedBall : AHazeActor
{
	access Visualizer = private, UDentistLaunchedBallVisualizer, UDentistLaunchedBallMultiSimulatorVisualizer, ADentistLaunchedBallMultiSimulator;

	default TickGroup = ETickingGroup::TG_PrePhysics;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;
	default SphereComp.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRootComp;

	UPROPERTY(DefaultComponent, Attach = MeshRootComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDentistLaunchedBallSimulationComponent SimulationComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float PlayerImpactAwayImpulse = 1000;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	bool bPlayerImpactNeverLaunchDownwards = true;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	float PlayerImpactVerticalImpulse = 1500;

	UPROPERTY(EditAnywhere, Category = "Player Impact")
	FDentistToothApplyRagdollSettings PlayerImpactRagdollSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Impact")
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Impact")
	UForceFeedbackEffect ImpactForceFeedback;

	UPROPERTY(BlueprintReadOnly)
	FDentistLaunchedBallStartMoving OnStartMoving;

	UPROPERTY(BlueprintReadOnly)
	FDentistLaunchedBallOnImpact OnImpact;

	UPROPERTY(BlueprintReadOnly)
	FDentistLaunchedBallHitWater OnHitWater;

	private bool bVisible = true;
	private int PreviousMoveLoopCount = 0;
	private int PreviousHitWaterLoopCount = 0;
	private int ProcessedImpacts = 0;
	private bool bWasRolling = false;
	private bool bWasFalling = false;

	#if EDITOR
	access:Visualizer float VisualizationStartTime = 0;
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SimulationComp.OnTickSimulationDelegate.BindUFunction(this, n"OnTickSimulation");
		OnImpact.AddUFunction(this, n"OnSimulationImpact");
		OnHitWater.AddUFunction(this, n"OnSimulationHitWater");

#if !RELEASE
		DevTogglesDentist::PrintLaunchedBallRollEvents.MakeVisible();
		DevTogglesDentist::PrintLaunchedBallFallEvents.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const FVector AngularVelocity =  ActorVelocity.CrossProduct(FVector::UpVector);

		const float RotationSpeed = (AngularVelocity.Size() / GetRadius());
		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaSeconds * -1);
		
		MeshRootComp.AddWorldRotation(DeltaQuat);

		if(bWasRolling)
		{
			TickRollingForceFeedback(DeltaSeconds);
		}
	}

	UFUNCTION()
	private void OnTickSimulation(float LoopTime, float LoopDuration, int LoopCount)
	{
		EDentistLaunchedBallLoopState LoopState;
		const float MoveTime = SimulationComp.Simulation.GetMoveTime(LoopTime, LoopState);

		const bool bIsNewLoop = PreviousMoveLoopCount != LoopCount;
		const bool bHasHalted = LoopState == EDentistLaunchedBallLoopState::WaitingAtEnd && !SimulationComp.Simulation.HasHitWater();

		if(LoopState == EDentistLaunchedBallLoopState::Moving || bHasHalted)
		{			
			if(!bVisible)
				MakeVisible();
		}
		else
		{
			if(bVisible)
				MakeInvisible();
		}

		bool bIsRolling = false;
		bool bIsFalling = false;

		if(bIsNewLoop)
		{
			if(bWasRolling)
				StopRolling();

			if(bWasFalling)
				StopFalling();
		}

		switch(LoopState)
		{
			case EDentistLaunchedBallLoopState::WaitingAtStart:
			{
				const FDentistBallLauncherSimulationStep StartStep = SimulationComp.Simulation.GetFirstStep();
				SetActorLocation(StartStep.GetPlaybackLocation(SimulationComp.SimulationLoop));
				SetActorVelocity(FVector::ZeroVector);
				break;
			}

			case EDentistLaunchedBallLoopState::Moving:
			{
				const FDentistBallLauncherSimulationStep SimulationStep = GetStepAtTime(MoveTime, bIsRolling);

				FVector PreviousLocation = ActorLocation;

				SetActorLocation(SimulationStep.GetPlaybackLocation(SimulationComp.SimulationLoop));
				SetActorVelocity(SimulationStep.Velocity);

				if(bIsNewLoop)
				{
					// Don't sweep if it is a new loop, because then we could sweep from the end to the start location
					OnStartMoving.Broadcast();

					FDentistLaunchedBallOnLaunchedEventData EventData;
					EventData.Location = ActorLocation;
					EventData.Velocity = ActorVelocity;
					UDentistLaunchedBallEventHandler::Trigger_OnLaunched(this, EventData);

					ProcessedImpacts = 0;
				}
				else
				{
					if(ActorVelocity.Z < -750)
						bIsFalling = true;

					for(int i = ProcessedImpacts; i < SimulationComp.Simulation.Impacts.Num(); i++)
					{
						const bool bIsFirstImpact = i == 0;
						const FDentistLaunchedBallImpact Impact = SimulationComp.Simulation.Impacts[i];

						if(Impact.Time < MoveTime)
						{
							ProcessedImpacts++;
							OnImpact.Broadcast(this, Impact, bIsFirstImpact);

							UDentistLaunchedBallImpactResponseComponent ResponseComp = Impact.GetImpactResponseComponent();
							if(ResponseComp != nullptr)
								ResponseComp.OnImpact.Broadcast(this, Impact, bIsFirstImpact);
						}
					}

					for(auto Player : Game::Players)
					{
						SweepForPlayer(Player, PreviousLocation, ActorLocation);
					}
				}

				PreviousMoveLoopCount = LoopCount;
				break;
			}

			case EDentistLaunchedBallLoopState::WaitingAtEnd:
			{
				if(bWasRolling)
				{
					bWasRolling = false;
					UDentistLaunchedBallEventHandler::Trigger_OnStopRolling(this);
				}

				const FDentistBallLauncherSimulationStep EndStep = SimulationComp.Simulation.GetLastStep();
				SetActorLocation(EndStep.GetPlaybackLocation(SimulationComp.SimulationLoop));
				SetActorVelocity(FVector::ZeroVector);
				break;
			}
		}

		if(SimulationComp.Simulation.HasHitWater())
		{
			const bool bHasReachedEnd = LoopState == EDentistLaunchedBallLoopState::WaitingAtEnd;
			if(bHasReachedEnd && PreviousHitWaterLoopCount < LoopCount)
			{
				// If we reached the end, and haven't broadcast hitting the water yet, do so!
				PreviousHitWaterLoopCount = LoopCount;
				OnHitWater.Broadcast();
			}

			if(bIsNewLoop && PreviousHitWaterLoopCount < LoopCount - 1)
			{
				// If we reached a new loop, and never broadcast hitting the water last loop, do so!
				PreviousHitWaterLoopCount = LoopCount - 1;
				OnHitWater.Broadcast();
			}
		}

		if(bIsRolling != bWasRolling)
		{
			if(bIsRolling)
				StartRolling();
			else
				StopRolling();
		}

		if(bIsFalling != bWasFalling)
		{
			if(bIsFalling)
				StartFalling();
			else
				StopFalling();
		}
	}

	private void MakeVisible()
	{
		check(!bVisible);

		bVisible = true;
		RemoveActorCollisionBlock(this);
		SetActorHiddenInGame(false);
	}

	private void MakeInvisible()
	{
		check(bVisible);

		bVisible = false;
		AddActorCollisionBlock(this);
		SetActorHiddenInGame(true);
	}

	private void SweepForPlayer(AHazePlayerCharacter Player, FVector Start, FVector End)
	{
		if(Start.Equals(End))
			return;

		if(!Player.HasControl())
			return;
		
		FHazeTraceSettings TraceSettings = Trace::InitAgainstComponent(Player.CapsuleComponent);
		TraceSettings.UseSphereShape(SphereComp.SphereRadius);

		FHitResult Hit = TraceSettings.QueryTraceComponent(Start, End);
		if(Hit.bBlockingHit && Hit.Actor == Player)
		{
			auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
			if(ResponseComp == nullptr)
				return;

			FVector AwayDirection = (Player.ActorLocation - ActorLocation);
			if(bPlayerImpactNeverLaunchDownwards)
			{
				if(AwayDirection.Z < 0)
					AwayDirection.Z = 0;
			}
			AwayDirection.Normalize();

			const FVector Impulse = (AwayDirection * PlayerImpactAwayImpulse) + (FVector::UpVector * PlayerImpactVerticalImpulse);

			ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, PlayerImpactRagdollSettings);

			FDentistLaunchedBallOnLaunchPlayerEventData EventData;
			EventData.Player = Player;
			UDentistLaunchedBallEventHandler::Trigger_OnLaunchPlayer(this, EventData);

			auto MoveComp = UPlayerMovementComponent::Get(Player);
			if(MoveComp == nullptr)
				return;

			const FVector Delta = End - Start;

			MoveComp.HandlePlayerMoveInto(Delta, SphereComp, true, Name.ToString());
		}
	}

	private void StartRolling()
	{
		UDentistLaunchedBallEventHandler::Trigger_OnStartRolling(this);
		bWasRolling = true;

#if !RELEASE
		if(DevTogglesDentist::PrintLaunchedBallRollEvents.IsEnabled())
			Debug::DrawDebugString(ActorLocation, "Start Rolling", FLinearColor::Green, 1, 2);
#endif
	}

	private void StopRolling()
	{
		UDentistLaunchedBallEventHandler::Trigger_OnStopRolling(this);
		bWasRolling = false;

#if !RELEASE
		if(DevTogglesDentist::PrintLaunchedBallRollEvents.IsEnabled())
			Debug::DrawDebugString(ActorLocation, "Stop Rolling", FLinearColor::Red, 1, 2);
#endif
	}

	private void TickRollingForceFeedback(float DeltaTime)
	{
		// Hannes TODO: Force Feedback!
		//ForceFeedback::PlayWorldForceFeedbackForFrame()
	}

	private void StartFalling()
	{
		UDentistLaunchedBallEventHandler::Trigger_OnStartFalling(this);
		bWasFalling = true;

#if !RELEASE
		if(DevTogglesDentist::PrintLaunchedBallFallEvents.IsEnabled())
			Debug::DrawDebugString(ActorLocation, "Start Falling", FLinearColor::Green, 1, 2);
#endif
	}

	private void StopFalling()
	{
		UDentistLaunchedBallEventHandler::Trigger_OnStopFalling(this);
		bWasFalling = false;

#if !RELEASE
		if(DevTogglesDentist::PrintLaunchedBallFallEvents.IsEnabled())
			Debug::DrawDebugString(ActorLocation, "Stop Falling", FLinearColor::Red, 1, 2);
#endif
	}

	FDentistBallLauncherSimulationStep GetStepAtTime(float Time, bool&out bOutIsRolling) const
	{
		return SimulationComp.Simulation.GetStepAtTime(Time, bOutIsRolling);
	}

	float GetRadius() const
	{
		return SphereComp.SphereRadius;
	}

	UFUNCTION()
	private void OnSimulationImpact(ADentistLaunchedBall LaunchedBall, FDentistLaunchedBallImpact Impact, bool bIsFirstImpact)
	{
		FVector ImpactLocation = Impact.GetImpactPoint();
		FRotator ImpactRotation = FRotator::MakeFromZ(Impact.GetImpactNormal());

		FDentistLaunchedBallOnImpactEventData EventData;
		EventData.bIsFirstImpact = bIsFirstImpact;
		EventData.HitComponent = Impact.HitComponent.Get();
		EventData.ImpactLocation = ImpactLocation;
		EventData.ImpactRotation = ImpactRotation;
		EventData.Impulse = Impact.Impulse;
		UDentistLaunchedBallEventHandler::Trigger_OnImpact(this, EventData);

		if(ImpactCameraShake != nullptr)
			SpawnImpactCameraShake(ImpactLocation);

		if(ImpactForceFeedback != nullptr)
			SpawnImpactForceFeedback(ImpactLocation);
	}

	private void SpawnImpactCameraShake(FVector ImpactLocation) const
	{
		for(auto Player : Game::Players)
			Player.PlayWorldCameraShake(ImpactCameraShake, this, ImpactLocation, 500, 2000);
	}

	private void SpawnImpactForceFeedback(FVector ImpactLocation) const
	{
		ForceFeedback::PlayWorldForceFeedback(ImpactForceFeedback, ImpactLocation, false, this);
	}

	UFUNCTION()
	private void OnSimulationHitWater()
	{
		check(SimulationComp.Simulation.HasHitWater());

		FVector SplashLocation = SimulationComp.Simulation.GetLastStep().GetPlaybackLocation(SimulationComp.SimulationLoop);
		SplashLocation.Z = Dentist::GetChocolateWaterHeight(SplashLocation);

		FDentistLaunchedBallOnHitWaterEventData EventData;
		EventData.SplashLocation = SplashLocation;
		UDentistLaunchedBallEventHandler::Trigger_OnHitWater(this, EventData);
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Playback")
	private void PlayVisualizationFromStart()
	{
		SimulationComp.PlayVisualizationFromStart();
	}

	UFUNCTION(CallInEditor, Category = "Simulation")
	private void RunSimulation()
	{
		SimulationComp.RunSimulation();
	}
#endif
};