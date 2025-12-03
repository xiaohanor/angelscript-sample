class ASummitKnightDummyUnit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent CharacterMesh0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightAttach)
	USummitKnightSwordComponent Sword;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.bMeltAllMaterials = false;

	AHazeActor Target;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal KnightHeadActor; 

	UPROPERTY()
	FVector KnightStart;

	// temp
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AnimationLocomotion;

	// temp
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AnimationAttack;

	// temp
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AnimationStunned;

	// temp
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AnimationKnockedDown;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor StaticCamera;

	// temp
	UPROPERTY(EditInstanceOnly)
	AGiantBreakableObject BreakFloor;

	// temp
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike KnightMoveKnockdown;

	// temp
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike KnightMoveTwo;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
//		Target = Game::GetClosestPlayer(ActorLocation);
		KnightStart = CharacterMesh0.WorldLocation;

		KnightMoveKnockdown.BindUpdate(this, n"UpdateKnightMoveKnockdown");
		KnightMoveKnockdown.BindFinished(this, n"FinishedKnightMoveKnockdown");
		KnightMoveTwo.BindUpdate(this, n"UpdateKnightMoveTwo");

		// Play Slot Animation
		FHazeSlotAnimSettings Params;
		Params.BlendTime = 0.2;
		Params.BlendOutTime = 0.2;
		Params.bLoop = true;
		PlaySlotAnimation(AnimationLocomotion, Params);

		// Hide Bone by Name
		CharacterMesh0.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);

		// Attach Head actor to Component
		KnightHeadActor.AttachToComponent(CharacterMesh0, n"Head", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
	}


	UFUNCTION()
	private void UpdateKnightMoveKnockdown(float CurrentValue)
	{
		FVector TargetLocation = FVector(KnightStart.X, KnightStart.Y, 750.0);
		ActorLocation = Math::Lerp(KnightStart, TargetLocation, CurrentValue);
	}

	UFUNCTION()
	private void FinishedKnightMoveKnockdown()
	{
		// On finished timelike, deactivate Niagara effect component, vfx_lightning_impact_01

		FHazeSlotAnimSettings ParamsLoco;
		ParamsLoco.BlendTime = 0.2;
		ParamsLoco.BlendOutTime = 0.2;
		ParamsLoco.bLoop = true;
		PlaySlotAnimation(AnimationLocomotion, ParamsLoco);
	}

	UFUNCTION()
	private void UpdateKnightMoveTwo(float CurrentValue)
	{
		ActorLocation = Math::Lerp(ActorLocation, FVector(ActorLocation.X, ActorLocation.Y, 52000), CurrentValue);
	}

	UFUNCTION(BlueprintEvent)
	void BP_AnimationDone()
	{		
	}

	UFUNCTION()
	void PerformSwordAttack()
	{
		// Set actor rotation
		SetActorRelativeRotation(FRotator(-20, -90, 0));
		Sword.SetRelativeRotation(FRotator(0,-90,90));

		// Attack animation
		FHazeSlotAnimSettings Params;
		Params.BlendTime = 0.2;
		Params.BlendOutTime = 0.2;
		Params.PlayRate = 1.0;
		PlaySlotAnimation(AnimationAttack, Params);

		// Delay 1.61s

		// Set play rate 0.0, halt animation (maybe use pause at end bool instead?)
		// SetSlotAnimationPlayRate(AnimationAttack, 0);

		// Play camera shake
		Game::Mio.PlayCameraShake(CameraShake, this);
		Game::Zoe.PlayCameraShake(CameraShake, this);
	}

	// Make into capability
	UFUNCTION()
	void OnCrushedFirst()
	{
		// Play slot animation
		SetSlotAnimationPlayRate(AnimationStunned, 1.0);
		FHazeSlotAnimSettings Params;
		Params.BlendTime = 0.2;
		Params.BlendOutTime = 0.2;
		Params.bLoop = true;
		PlaySlotAnimation(AnimationStunned, Params);
		
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			Player.ActivateCamera(StaticCamera, 2.0, this, EHazeCameraPriority::High);
		}

		SetActorRelativeRotation(FRotator(0,-90,0));

		// TODO: Delay 3.0, then play animation
		FHazeSlotAnimSettings ParamsLoco;
		ParamsLoco.BlendTime = 0.2;
		ParamsLoco.BlendOutTime = 0.2;
		ParamsLoco.bLoop = true;
		PlaySlotAnimation(AnimationLocomotion, ParamsLoco);

		KnightHeadActor.TriggerRegrow();

		// TODO: Delay 2.0, then
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.DeactivateCamera(StaticCamera, -1.0);
			Player.ClearViewSizeOverride(this);
		}
	}

	// make into capability
	UFUNCTION()
	void OnCrushedSecond()
	{
		// Spawn Niagara effect vfx_enemy_crystal_02 at KnightHead location

		// Play slot animation (none selected in BP original)

		// Set fullscreen
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			Player.ActivateCamera(StaticCamera, 2.0, this, EHazeCameraPriority::High);
		}

		// Delay 2.0s

		// Break a giant object w impact direction z = -10, impulse = 660000.0
		BreakFloor.OnBreakGiantObject(FVector(0,0,-10.0), 660000);

		// Spawn niagara effect vfx_explosion_fire_rough_big

		// Play TimeLike KnightMoveTwo
		KnightMoveTwo.PlayFromStart();
	}

	UFUNCTION()
	void KnockedDown()
	{
		// Activate Niagara effect component, vfx_lightning_impact_01


		//slot anim knockdown
		FHazeSlotAnimSettings Params;
		Params.BlendTime = 0.2;
		Params.BlendOutTime = 0.2;
		Params.bLoop = true;
		PlaySlotAnimation(AnimationKnockedDown, Params);

		// Knight move timelike
		KnightMoveKnockdown.PlayFromStart();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	UFUNCTION(DevFunction)
	void TestPerformSwordAttack()
	{
		PerformSwordAttack();
	}


	UFUNCTION(DevFunction)
	void TestCrushTwo()
	{
		OnCrushedSecond();
	}

	UFUNCTION(DevFunction)
	void TestKnockedDown()
	{
		KnockedDown();
	}
};