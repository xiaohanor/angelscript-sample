event void FSlidingIceBlockEvent();
class ATundra_SlidingIceBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchInteract1;
	default PunchInteract1.RelativeLocation = FVector(570.0, 0.0, 300.0);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchInteract2;
	default PunchInteract2.RelativeLocation = FVector(-570.0, 0.0, 300.0);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchInteract3;
	default PunchInteract3.RelativeLocation = FVector(0.0, 570.0, 300.0);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchInteract4;
	default PunchInteract4.RelativeLocation = FVector(0.0, -570.0, 300.0);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent KillBox;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent SlamComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UMovableCameraShakeComponent MovableCamShakeComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> OnImpactCamShake;

	UPROPERTY(EditInstanceOnly)
	AHazeActor TargetPlatform;

	UPROPERTY()
	FSlidingIceBlockEvent OnSlidingIceBlockHitCrackWall;
	UPROPERTY()
	FSlidingIceBlockEvent OnIceBlockMovedDown;
	UPROPERTY()
	FSlidingIceBlockEvent OnIceBlockStopped;
	UPROPERTY()
	FSlidingIceBlockEvent OnOutsideGrid;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FHazeTimeLike MoveIceBlockDownTimelike;
	default MoveIceBlockDownTimelike.Duration = 1;

	UPROPERTY(EditInstanceOnly)
	ATundra_IcePalace_CrackedWall TargetBreakableWall;

	bool bShouldMove = false;
	bool bMoveShouldIgnoreGrid = false;
	FTundraGridPoint MoveDirection;
	float MoveSpeed = 2000;
	ATundra_IcePalace_SlidingIceBlockBoard Board;
	FTundraGridPoint CurrentGridPoint;
	bool bHasBeenOutsideOfGrid = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		//SlamComp.OnGroundSlam.AddUFunction(this, n"OnSlam");
		PunchInteract1.OnPunch.AddUFunction(this, n"OnPunch");
		PunchInteract2.OnPunch.AddUFunction(this, n"OnPunch");
		PunchInteract3.OnPunch.AddUFunction(this, n"OnPunch");
		PunchInteract4.OnPunch.AddUFunction(this, n"OnPunch");

		PunchInteract1.DisallowedGroundActors.Add(this);
		PunchInteract2.DisallowedGroundActors.Add(this);
		PunchInteract3.DisallowedGroundActors.Add(this);
		PunchInteract4.DisallowedGroundActors.Add(this);

		KillBox.OnComponentBeginOverlap.AddUFunction(this, n"OnKillBoxOverlap");
		Board = TListedActors<ATundra_IcePalace_SlidingIceBlockBoard>().Single;
		CurrentGridPoint = Board.GetClosestGridPoint(ActorLocation);
		FVector GridLocation = Board.GetWorldLocationOfGridPoint(CurrentGridPoint);
		ActorLocation = FVector(GridLocation.X, GridLocation.Y, ActorLocation.Z);

		MoveIceBlockDownTimelike.BindUpdate(this, n"MoveIceBlockDownTimelineUpdate");
		MoveIceBlockDownTimelike.BindFinished(this, n"MoveIceBlockDownTimelikeFinished");
	}

	UFUNCTION()
	private void OnKillBoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                              const FHitResult&in SweepResult)
	{
		if(!bShouldMove)
			return;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if(Player.IsMio())
			return;

		FPlayerDeathDamageParams DeathParams;
		DeathParams.ImpactDirection = MoveDirection.ToVector();
		DeathParams.ForceScale = 10.0;

		Player.KillPlayer(DeathParams, DeathEffect);
		UTundra_IcePalace_SlidingIceBlockEffectHandler::Trigger_OnKillPlayer(this, FTundra_IcePalace_SlidingIceBlockKillPlayerEffectParams(Player));
	}

	UFUNCTION()
	private void OnPunch(FVector PlayerLocation)
	{
		TryMove(GetMoveDirectionBasedOnSlamLocation(PlayerLocation));
	}

	UFUNCTION()
	private void OnSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		TryMove(GetMoveDirectionBasedOnSlamLocation(PlayerLocation));
	}

	private void TryMove(FTundraGridPoint Direction)
	{
		if(!Game::Mio.HasControl())
			return;

		FTundraGridPoint NextGridPoint = CurrentGridPoint + Direction;
		if(Board.IsGridPointBlocked(NextGridPoint))
			return;

		bool bNextIsOutsideGrid = !Board.IsGridPointWithinGrid(NextGridPoint);
		bool bCurrentIsExitNode = Board.IsGridPointExitNode(CurrentGridPoint);
		if(bNextIsOutsideGrid && !bCurrentIsExitNode)
			return;

		NetMoveBlock(Direction);
	}

	FTundraGridPoint GetMoveDirectionBasedOnSlamLocation(FVector PlayerLocation)
	{
		FVector Dir = (ActorLocation - PlayerLocation).GetSafeNormal2D();
		FVector Direction = Math::GetClosestBasisVectorToVector(ActorTransform, Dir);

		return FTundraGridPoint(Direction);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HandleMove(DeltaTime);
	}

	private void HandleMove(float DeltaTime)
	{
		if(!HasControl())
		{
			auto Position = SyncedActorPosition.GetPosition();
			ActorLocation = Position.WorldLocation;
			ActorRotation = Position.WorldRotation;
			CurrentGridPoint = Board.GetClosestGridPoint(ActorLocation);
			return;
		}

		if(!bShouldMove)
			return;

		float Delta = MoveSpeed * DeltaTime;

		if(bMoveShouldIgnoreGrid)
		{
			if(!bHasBeenOutsideOfGrid)
			{
				CrumbOnOutsideGrid();
			}

			if(ActorLocation.Y <= TargetPlatform.ActorLocation.Y)
			{
				CrumbOnTopOfTargetPlatform();
				return;
			}

			FVector DeltaVector = MoveDirection.ToVector() * Delta;
			ActorLocation += DeltaVector;
			return;
		}
		
		while(true)
		{
			FTundraGridPoint NextGridPoint = CurrentGridPoint + MoveDirection;
			bool bPointBlocked = Board.IsGridPointBlocked(NextGridPoint);
			bool bPointOutsideGrid = !Board.IsGridPointWithinGrid(NextGridPoint);
			if(bPointBlocked || bPointOutsideGrid)
			{
				if(bPointOutsideGrid && Board.IsGridPointExitNode(CurrentGridPoint))
				{
					bMoveShouldIgnoreGrid = true;
					ActorLocation += MoveDirection.ToVector() * Delta;
					return;
				}

				CrumbOnImpact(bPointBlocked, FTundra_IcePalace_SlidingIceBlockMoveEffectParams(MoveDirection.ToVector()), CurrentGridPoint);
				return;
			}

			float MaxDelta = GetDistanceToGridPoint(NextGridPoint);
			if(Delta < MaxDelta)
			{
				ActorLocation += MoveDirection.ToVector() * Delta;
				return;
			}

			ActorLocation += MoveDirection.ToVector() * MaxDelta;
			Delta -= MaxDelta;
			CurrentGridPoint = NextGridPoint;
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnOutsideGrid()
	{
		OnOutsideGrid.Broadcast();
		bHasBeenOutsideOfGrid = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnImpact(bool bImpactOnBlocker, FTundra_IcePalace_SlidingIceBlockMoveEffectParams Params, FTundraGridPoint GridPoint)
	{
		MovableCamShakeComp.DeactivateMovableCameraShake();
		for(auto Player : Game::Players)
			Player.PlayWorldCameraShake(OnImpactCamShake, this, ActorLocation, 1000, 3500);

		CurrentGridPoint = GridPoint;
		FVector Location = Board.GetWorldLocationOfGridPoint(CurrentGridPoint);
		ActorLocation = FVector(Location.X, Location.Y, ActorLocation.Z);
		bShouldMove = false;

		if(bImpactOnBlocker)
			UTundra_IcePalace_SlidingIceBlockEffectHandler::Trigger_OnImpactOnBlocker(this, FTundra_IcePalace_SlidingIceBlockMoveEffectParams(MoveDirection.ToVector()));
		else
			UTundra_IcePalace_SlidingIceBlockEffectHandler::Trigger_OnImpactOnOuterConstraint(this, FTundra_IcePalace_SlidingIceBlockMoveEffectParams(MoveDirection.ToVector()));
	}

	bool IsOverlappingGridPoint(FTundraGridPoint GridPoint) const
	{
		if(bMoveShouldIgnoreGrid)
			return false;

		if(GridPoint == CurrentGridPoint)
			return true;

		if(bShouldMove && GridPoint == CurrentGridPoint + MoveDirection)
			return true;

		return false;
	}

	float GetDistanceToGridPoint(FTundraGridPoint GridPoint) const
	{
		FVector Location = Board.GetWorldLocationOfGridPoint(GridPoint);
		return Location.DistXY(ActorLocation);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnTopOfTargetPlatform()
	{
		bShouldMove = false;
		MovableCamShakeComp.DeactivateMovableCameraShake();
		SetActorTickEnabled(false);
		PunchInteract1.Disable(this);
		PunchInteract2.Disable(this);
		PunchInteract3.Disable(this);
		PunchInteract4.Disable(this);
		TargetPlatform.DestroyActor();

		OnIceBlockStopped.Broadcast();

		Timer::SetTimer(this, n"MoveBlockDown", 0.5);
		UTundra_IcePalace_SlidingIceBlockEffectHandler::Trigger_OnImpactOnGate(this, FTundra_IcePalace_SlidingIceBlockMoveEffectParams(MoveDirection.ToVector()));
	}

	UFUNCTION()
	void MoveBlockDown()
	{
		MoveIceBlockDownTimelike.PlayFromStart();
		UTundra_IcePalace_SlidingIceBlockEffectHandler::Trigger_OnMoveDownIntoGround(this);
	}

	UFUNCTION()
	private void MoveIceBlockDownTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(0, 0, -600), CurrentValue));
	}

	UFUNCTION()
	private void MoveIceBlockDownTimelikeFinished()
	{
		OnIceBlockMovedDown.Broadcast();
	}

	UFUNCTION(NetFunction)
	private void NetMoveBlock(FTundraGridPoint Direction)
	{
		MoveDirection = Direction;
		bShouldMove = true;

		FTundraGridPoint EdgeNormal;
		bMoveShouldIgnoreGrid = IsOnExitNode(EdgeNormal) && EdgeNormal == Direction;
		MovableCamShakeComp.ActivateMovableCameraShake();
		UTundra_IcePalace_SlidingIceBlockEffectHandler::Trigger_OnStartSlide(this, FTundra_IcePalace_SlidingIceBlockMoveEffectParams(MoveDirection.ToVector()));
	}

	bool IsOnExitNode(FTundraGridPoint&out EdgeNormal)
	{
		Board.IsGridPointOnEdge(CurrentGridPoint, EdgeNormal);
		return Board.IsGridPointExitNode(CurrentGridPoint);
	}
}