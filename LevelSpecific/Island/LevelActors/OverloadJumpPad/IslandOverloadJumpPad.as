asset IslandJumpPadPlayerAirSettings of UPlayerAirMotionSettings
{
	DragOfExtraHorizontalVelocity = 0.0;
	AirControlMultiplier = 0.0;
} 

enum EIslandOverloadJumpPadMovementState
{
	GoingDown,
	Resetting,
	Idle,
	Launching
}

class AIslandOverloadJumpPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LaunchRoot;

	UPROPERTY(DefaultComponent, Attach = LaunchRoot)
	UStaticMeshComponent PadMesh;

	UPROPERTY(DefaultComponent, Attach = LaunchRoot)
	UBoxComponent PlayerEnterBox;

	UPROPERTY(DefaultComponent)
	USceneComponent LandLocation;
	default LandLocation.RelativeLocation = FVector(2000, 0, 0);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverloadJumpPadLaunchCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverloadJumpPadIdleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverloadJumpPadHandshakeCapability");

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandOverloadJumpPadDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AIslandOverloadShootablePanel Panel;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AIslandOverloadPanelListener PanelListener;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bRequireSecondPanel = false;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = bRequireSecondPanel, EditConditionHides))
	AIslandOverloadShootablePanel SecondPanel;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = bRequireSecondPanel, EditConditionHides))
	AIslandOverloadJumpPad OtherJumpPad;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float PlayerGravityAmount = 2385;
	
	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UForceFeedbackEffect LaunchFF;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float PlayerTerminalVelocity = 2500;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float HeightToReach = 10000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PadRetractAmount = 100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchDuration = 0.05;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EHazeSelectPlayer UsableByPlayer;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DelayBeforeResumePOI = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartDisabled = false;

	bool bIsLaunching = false;

	bool bFirstPanelIsOvercharged = false;
	bool bSecondPanelIsOverCharged = false;
	bool bHandshakeSuccessful = false;

	EIslandOverloadJumpPadMovementState CurrentState;
	TArray<AHazePlayerCharacter> PlayersInsideBox;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentState = EIslandOverloadJumpPadMovementState::Idle;
		TArray<AHazePlayerCharacter> Players = Game::GetPlayersSelectedBy(UsableByPlayer);
		devCheck(Players.Num() == 1, f"Jump pad has UsableByPlayer setting {UsableByPlayer} which is currently not supported");
		SetActorControlSide(Players[0]);

		PlayerEnterBox.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxBeginOverlap");
		PlayerEnterBox.OnComponentEndOverlap.AddUFunction(this, n"OnBoxEndOverlap");
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto TemporalLog = TEMPORAL_LOG(this);

		if(CurrentState == EIslandOverloadJumpPadMovementState::Idle)
			TemporalLog.PersistentStatus("Idle", FLinearColor::Black);
		else if (CurrentState == EIslandOverloadJumpPadMovementState::GoingDown)
			TemporalLog.PersistentStatus("Going Down", FLinearColor::Red);
		else if(CurrentState == EIslandOverloadJumpPadMovementState::Resetting)
			TemporalLog.PersistentStatus("Resetting", FLinearColor::Green);
		else if(CurrentState == EIslandOverloadJumpPadMovementState::Launching)
			TemporalLog.PersistentStatus("Launching", FLinearColor::White);
	}
#endif

	UFUNCTION(NotBlueprintCallable)
	private void OnBoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                               UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                               const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(!Player.IsSelectedBy(UsableByPlayer))
			return;

		PlayersInsideBox.AddUnique(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBoxEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersInsideBox.RemoveSingleSwap(Player);
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	private void SetRotationTowardsImpulse()
	{
		FVector Impulse = Trajectory::CalculateVelocityForPathWithHeight(ActorLocation, LandLocation.WorldLocation, PlayerGravityAmount, HeightToReach, PlayerTerminalVelocity);
		FRotator QuatToImpulse = FRotator::MakeFromZ(Impulse);
		LaunchRoot.SetWorldRotation(QuatToImpulse);
	}

	void TogglePanelForPlayer(AHazePlayerCharacter Player, bool bActivate, bool bFirstPanel)
	{
		if(Panel.bResetChargeOnOvercharge)
			return;

		if(bActivate)
		{
			if(bFirstPanel)
			{
				Panel.OverchargeComp.UnblockImpactForPlayer(Player, this);
				Panel.TargetComp.EnableForPlayer(Player, this);
			}
			else
			{
				SecondPanel.OverchargeComp.UnblockImpactForPlayer(Player, this);
				SecondPanel.TargetComp.EnableForPlayer(Player, this);
			}
		}
		else
		{
			if(bFirstPanel)
			{
				Panel.OverchargeComp.BlockImpactForPlayer(Player, this);
				Panel.TargetComp.DisableForPlayer(Player, this);
			}
			else
			{
				SecondPanel.OverchargeComp.BlockImpactForPlayer(Player, this);
				SecondPanel.TargetComp.DisableForPlayer(Player, this);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	float GetPanelAlpha()
	{
		float Alpha = bFirstPanelIsOvercharged ? 1.0 : Panel.OverchargeComp.ChargeAlpha;

		if(bRequireSecondPanel)
		{
			float SecondPanelAlpha = bSecondPanelIsOverCharged ? 
				1.0 : SecondPanel.OverchargeComp.ChargeAlpha;
			Alpha += SecondPanelAlpha;
			Alpha *= 0.5;
		}
		return Alpha;
	}
};

class UIslandOverloadJumpPadPlayerComponent : UActorComponent
{
	float LastLaunchedTime;
}

#if EDITOR
class UIslandOverloadJumpPadDummyComponent : UActorComponent {}

class UIslandOverloadJumpPadComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandOverloadJumpPadDummyComponent;

	const float PlayerGravity = 2385.0;
	const float PlayerTerminalVelocity = 2500.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UIslandOverloadJumpPadDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		auto JumpPad = Cast<AIslandOverloadJumpPad>(Comp.Owner);
		if(JumpPad == nullptr)
			return;

		const FVector Origin = JumpPad.ActorLocation;
		DrawWireSphere(Origin, 40, FLinearColor::Red, 10);
		if(JumpPad.LandLocation == nullptr)
			return;
		
		const FVector Target = JumpPad.LandLocation.WorldLocation;
		DrawWireSphere(Target, 40, FLinearColor::Green, 10);

		FVector Velocity = Trajectory::CalculateVelocityForPathWithHeight(Origin, Target, PlayerGravity, JumpPad.HeightToReach, PlayerTerminalVelocity);
		FVector HighestPoint = Trajectory::TrajectoryHighestPoint(Origin, Velocity, PlayerGravity, FVector::UpVector);

		FTransform WorldTransform = FTransform::MakeFromXZ(FVector::ForwardVector, FVector::DownVector);
		FVector LocalOrigin = WorldTransform.InverseTransformPosition(Origin);
		FVector LocalDestination = WorldTransform.InverseTransformPosition(Target);
		FVector LocalHighestPoint = WorldTransform.InverseTransformPosition(HighestPoint);
		
		float ParabolaHeight = LocalHighestPoint.Z - (LocalOrigin.Z < LocalDestination.Z ? LocalOrigin.Z : LocalDestination.Z);
		float ParabolaBase = LocalOrigin.DistXY(LocalDestination);

		float ParabolaLengthSqrRt = Math::Sqrt(4 * Math::Square(ParabolaHeight) + Math::Square(ParabolaBase));
		float ParabolaLength = ParabolaLengthSqrRt + (Math::Square(ParabolaBase) / (2 * ParabolaBase)) * Math::Loge((2 * ParabolaHeight + ParabolaLengthSqrRt) / ParabolaBase);
		// ¯\_(ツ)_/¯
		ParabolaLength *= 2.5;

		Trajectory::FTrajectoryPoints Points = Trajectory::CalculateTrajectory(Origin, ParabolaLength, Velocity, PlayerGravity, 1.5, PlayerTerminalVelocity);

		for(int i=0; i<Points.Positions.Num() - 1; ++i)
		{
			FVector Start = Points.Positions[i];
			FVector End = Points.Positions[i + 1];
			bool bDone = false;

			if((HighestPoint - Target).GetSafeNormal().DotProduct((End - Target).GetSafeNormal()) < 0.0)
			{
				End = Target;
				bDone = true;
			}

			DrawLine(Start, End, FLinearColor::Yellow, 10);
			if(bDone)
				break;
		}

		FBox LocalBoundingBox = JumpPad.PadMesh.ComponentLocalBoundingBox;
		FVector BoxExtent = LocalBoundingBox.Extent;
		FVector DrawBackLocation = JumpPad.PadMesh.WorldLocation - JumpPad.LaunchRoot.UpVector * (JumpPad.PadRetractAmount + BoxExtent.Z);
		DrawWireBox(DrawBackLocation, BoxExtent, JumpPad.LaunchRoot.ComponentQuat, FLinearColor::Purple, 10, false);
		DrawWorldString("Draw Back Location", DrawBackLocation, FLinearColor::Purple);
	}
}

#endif