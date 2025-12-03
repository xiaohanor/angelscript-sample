UCLASS(Abstract)
class UTeenDragonTailAttackBaseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(n"TeenDragon");
	default CapabilityTags.Add(n"TailAttack");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 150);

	protected int AttackIndex = 0;
	protected ETeenDragonAnimationState AttackState;
	protected ETeenDragonAnimationState SettleState;

	protected float AttackDuration;
	protected float SettleDuration;
	protected float ComboWindow;
	protected float ForwardMovementDistance;
	protected float AttackDamage;

	//ATeenDragon TeenDragon;
	//AHazePlayerCharacter Player;
	UPlayerTailTeenDragonComponent DragonComp;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	FQuat AttackRotation;
	bool bComboTriggered = false;
	bool bInSettleState = false;

	TArray<UTeenDragonTailAttackResponseComponent> HitComponents;
	TArray<USceneComponent> HitMeshes;

	bool bHavePreviousHitbox = false;
	FVector PreviousHitboxLocation;


	protected void GetAttackSettings(float& OutAttackDuration, float& OutSettleDuration, float& OutComboWindow, float& OutMovementDistance, float& OutAttackDamage) {}
	protected void GetAttackHitbox(FName& OutBone, FTransform& OutTransform, float& OutStartTime, float& OutEndTime) {}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//TeenDragon = Cast<ATeenDragon>(Owner);
		//Player = TeenDragon.Player;
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();

		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;

		// if (AttackIndex == 0)
		// {
		// 	if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
		// 		return false;
		// 	if (DragonComp.CurrentAttackComboIndex != -1)
		// 		return false;
		// }
		// else
		// {
		// 	if (DragonComp.CurrentAttackComboIndex != AttackIndex)
		// 		return false;
		// }

		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= AttackDuration + SettleDuration)
			return true;
		if (ActiveDuration >= AttackDuration && bComboTriggered)
			return true;
		if (DragonComp.CurrentAttackComboIndex != AttackIndex)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		DragonComp.CurrentAttackComboIndex = AttackIndex;
		DragonComp.AnimationState.Apply(AttackState, this);

		Player.PlayCameraShake(DragonComp.TailAttackCameraShake, this); 

		bComboTriggered = false;
		bInSettleState = false;
		bHavePreviousHitbox = false;
		AttackRotation = FQuat::MakeFromX(Player.ViewRotation.ForwardVector.GetSafeNormal2D());
		HitComponents.Reset();
		HitMeshes.Reset();

		GetAttackSettings(
			AttackDuration,
			SettleDuration,
			ComboWindow,
			ForwardMovementDistance,
			AttackDamage,
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		DragonComp.AnimationState.Clear(this);
		HitComponents.Reset();
		HitMeshes.Reset();

		if (bComboTriggered)
			DragonComp.CurrentAttackComboIndex = AttackIndex+1;
		else
			DragonComp.CurrentAttackComboIndex = -1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetMovementFacingDirection(AttackRotation);

		// Allow triggering the next attack in the combo
		if (!bComboTriggered && ComboWindow > 0.0)
		{
			if (ActiveDuration >= AttackDuration + SettleDuration - ComboWindow)
			{
				if (WasActionStarted(ActionNames::PrimaryLevelAbility))
				{
					bComboTriggered = true;
				}
			}
		}

		// Move into settle state after attack is done
		if (!bInSettleState)
		{
			if (ActiveDuration >= AttackDuration)
			{
				DragonComp.AnimationState.Apply(SettleState, this);
				bInSettleState = true;
			}
		}

		// Perform hits with anything that overlaps the hitbox for the attack
		FName HitboxBone;
		FTransform HitboxTransform;
		float HitboxStartTime = 0.0;
		float HitboxEndTime = 0.0;

		GetAttackHitbox(HitboxBone, HitboxTransform, HitboxStartTime, HitboxEndTime);

		if (ActiveDuration >= HitboxStartTime && ActiveDuration < HitboxEndTime)
		{
			FTransform BoneTransform = DragonComp.DragonMesh.GetSocketTransform(HitboxBone);
			FVector HitboxPosition = BoneTransform.TransformPositionNoScale(HitboxTransform.Location);

			if (bHavePreviousHitbox)
			{
				FHazeTraceSettings Trace;
				Trace.UseBoxShape(FVector(1.0, 1.0, 1.0) * HitboxTransform.Scale3D, BoneTransform.TransformRotation(HitboxTransform.Rotation));
				Trace.TraceWithChannel(ECollisionChannel::WeaponTraceZoe);
				Trace.IgnorePlayers();
				Trace.IgnoreActor(Owner);

				if (TeenDragonTailAttack::bDebugHitboxes)
					Trace.DebugDraw(2.0);

				FHitResultArray Hits = Trace.QueryTraceMulti(
					PreviousHitboxLocation,
					HitboxPosition,
				);
				for (auto Hit : Hits)
				{
					if (Hit.Actor == nullptr)
						continue;

					// Don't hit the same actor more than once per attack
					if (HitMeshes.Contains(Hit.Component))
						continue;
					HitMeshes.Add(Hit.Component);

					FTeenDragonTailAttackImpactParams Params;

					auto ResponseComp = UTeenDragonTailAttackResponseComponent::Get(Hit.Actor);
					if (ResponseComp != nullptr && !HitComponents.Contains(ResponseComp))
					{
						HitComponents.Add(ResponseComp);

						FTailAttackParams AttackEvent;
						AttackEvent.AttackComponent = Hit.Component;
						AttackEvent.WorldAttackLocation = Hit.ImpactPoint;

						AttackEvent.AttackDirection = (HitboxPosition - PreviousHitboxLocation).GetSafeNormal();
						AttackEvent.AttackForwardVector = AttackRotation.ForwardVector;
						AttackEvent.AttackDirection = AttackEvent.AttackDirection.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
						AttackEvent.PlayerInstigator = Player;
						AttackEvent.DamageDealt = AttackDamage;

						ResponseComp.OnHitByTailAttack.Broadcast(AttackEvent);
						Params.ImpactType = ResponseComp.ImpactType;
					}
					else
					{
						Params.ImpactType = ETailAttackImpactType::Nature;
					}

					Params.Location = Hit.ImpactPoint;
					Params.Normal = Hit.ImpactNormal;

					UTeenDragonTailAttackEventHandler::Trigger_TailAttackImpact(Player, Params);
				}
			}

			bHavePreviousHitbox = true;
			PreviousHitboxLocation = HitboxPosition;
		}

		// The dragon stands still while doing its attack
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{	
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				//Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));
				Movement.InterpRotationToTargetFacingRotation(16.0);

				if (!bInSettleState)
				{
					float ForwardMovementSpeed = ForwardMovementDistance / AttackDuration;
					Movement.AddHorizontalVelocity(AttackRotation.ForwardVector * ForwardMovementSpeed);
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"TailAttack");
		}
	}
}

class UTeenDragonTailFirstAttackCapability : UTeenDragonTailAttackBaseCapability
{
	default AttackIndex = 0;
	default TickGroupSubPlacement = 10;

	default AttackState = ETeenDragonAnimationState::TailFirstAttack;
	default SettleState = ETeenDragonAnimationState::TailFirstAttackSettle;

	void GetAttackSettings(float& OutAttackDuration, float& OutSettleDuration, float& OutComboWindow, float& OutMovementDistance, float& OutDamage) override
	{
		OutAttackDuration = TeenDragonTailAttack::FirstAttackDuration;
		OutSettleDuration = TeenDragonTailAttack::FirstAttackSettleTime;
		OutComboWindow = TeenDragonTailAttack::FirstAttackComboWindow;
		OutMovementDistance = TeenDragonTailAttack::FirstAttackForwardMovementDistance;
		OutDamage = TeenDragonTailAttack::FirstAttackDamage;
	}

	void GetAttackHitbox(FName& OutBone, FTransform& OutTransform, float& OutStartTime, float& OutEndTime) override
	{
		OutBone = TeenDragonTailAttack::FirstAttackHitboxBone;
		OutTransform = TeenDragonTailAttack::FirstAttackHitboxTransform;
		OutStartTime = TeenDragonTailAttack::FirstAttackHitboxStartTime;
		OutEndTime = TeenDragonTailAttack::FirstAttackHitboxEndTime;
	}
};

class UTeenDragonTailSecondAttackCapability : UTeenDragonTailAttackBaseCapability
{
	default AttackIndex = 1;
	default TickGroupSubPlacement = 9;

	default AttackState = ETeenDragonAnimationState::TailSecondAttack;
	default SettleState = ETeenDragonAnimationState::TailSecondAttackSettle;

	void GetAttackSettings(float& OutAttackDuration, float& OutSettleDuration, float& OutComboWindow, float& OutMovementDistance, float& OutDamage) override
	{
		OutAttackDuration = TeenDragonTailAttack::SecondAttackDuration;
		OutSettleDuration = TeenDragonTailAttack::SecondAttackSettleTime;
		OutComboWindow = TeenDragonTailAttack::SecondAttackComboWindow;
		OutMovementDistance = TeenDragonTailAttack::SecondAttackForwardMovementDistance;
		OutDamage = TeenDragonTailAttack::SecondAttackDamage;
	}

	void GetAttackHitbox(FName& OutBone, FTransform& OutTransform, float& OutStartTime, float& OutEndTime) override
	{
		OutBone = TeenDragonTailAttack::SecondAttackHitboxBone;
		OutTransform = TeenDragonTailAttack::SecondAttackHitboxTransform;
		OutStartTime = TeenDragonTailAttack::SecondAttackHitboxStartTime;
		OutEndTime = TeenDragonTailAttack::SecondAttackHitboxEndTime;
	}
};

class UTeenDragonTailThirdAttackCapability : UTeenDragonTailAttackBaseCapability
{
	default AttackIndex = 2;
	default TickGroupSubPlacement = 8;

	default AttackState = ETeenDragonAnimationState::TailThirdAttack;
	default SettleState = ETeenDragonAnimationState::TailThirdAttack;

	void GetAttackSettings(float& OutAttackDuration, float& OutSettleDuration, float& OutComboWindow, float& OutMovementDistance, float& OutDamage) override
	{
		OutAttackDuration = TeenDragonTailAttack::ThirdAttackDuration;
		OutSettleDuration = 0.0;
		OutComboWindow = 0.0;
		OutMovementDistance = TeenDragonTailAttack::ThirdAttackForwardMovementDistance;
		OutDamage = TeenDragonTailAttack::ThirdAttackDamage;
	}

	void GetAttackHitbox(FName& OutBone, FTransform& OutTransform, float& OutStartTime, float& OutEndTime) override
	{
		OutBone = TeenDragonTailAttack::ThirdAttackHitboxBone;
		OutTransform = TeenDragonTailAttack::ThirdAttackHitboxTransform;
		OutStartTime = TeenDragonTailAttack::ThirdAttackHitboxStartTime;
		OutEndTime = TeenDragonTailAttack::ThirdAttackHitboxEndTime;
	}
};