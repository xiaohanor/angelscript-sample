
namespace Dissolve
{
	UFUNCTION(BlueprintCallable)
	void TriggerDissolve(AHazeActor ActorToDissolve, const FVector TriggerLocation)
	{
		// find the component
		UTestDissolveComponent Comp = UTestDissolveComponent::Get(ActorToDissolve);

		if(Comp == nullptr)
		{
			// The actor needs to have the blueprint version of the component on it for it to work.
			check(false);
			return;
		}

		Comp.InitDissolve(TriggerLocation);
	}

	UFUNCTION(BlueprintCallable)
	void UpdateGlobalDissolveParams(
		UMaterialParameterCollection GlobalDissolveParams,
		const FVector DissolveLocation,
		const float DissolveRadius
	)
	{
		Material::SetScalarParameterValue(GlobalDissolveParams, n"DissolveRadius", DissolveRadius);
		Material::SetVectorParameterValue(GlobalDissolveParams, n"DissolveLocation", FLinearColor(DissolveLocation));
	}
}

UCLASS(Abstract)
class UTestDissolveComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	UMaterialParameterCollection GlobalDissolveParams;

	UPROPERTY()
	UNiagaraSystem DissolveEffect;

	// anim to play when dissolving
	UPROPERTY()
	FHazePlaySlotAnimationParams SlotParams;

	// Temp until we rewrite this, to prevent anything from spawning when the player dies.
	UPROPERTY()
	TSubclassOf<UDeathEffect> TEMP_DeathDissolveEffect;

	// The max radius of the sphere that consumes the charater
	UPROPERTY()
	float DissolveMaxRadius = 200;

	// how long it takes for the sphere to consumes the Character
	UPROPERTY()
	float DissolveDuration = 3;

	////////////////////////////////////////////////////////////
	// Transient

	bool bDesolveRequested = false;
	float ElapsedDissolveTime = 0;
	UNiagaraComponent DissolveEffect_Inst;
	FVector RelativePos = FVector::ZeroVector;
	AHazeActor HazeOwner = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}

	void InitDissolve(FVector InWorldPos)
	{
		RelativePos = Owner.GetActorTransform().InverseTransformPosition(InWorldPos);
		bDesolveRequested = true;
	}

	void ActivateDissolve()
	{
		const FVector DissolveOrigin = Owner.GetActorTransform().TransformPosition(RelativePos);

		// TriggerKnockdown(DissolveOrigin);
		HazeOwner.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), SlotParams);
		HazeOwner.BlockCapabilities(CapabilityTags::Movement, Instigator = this);

		// attach the niagara comp where the dissolve originates from
		DissolveEffect_Inst = Niagara::SpawnOneShotNiagaraSystemAttached(DissolveEffect, Owner.RootComponent);
		DissolveEffect_Inst.SetWorldLocation(DissolveOrigin);
	}

	void DeactivateDissolve()
	{
		// APlayerCharacter PlayerOwner = Cast<APlayerCharacter>(Owner);
		// if(PlayerOwner != nullptr)
		// {
		// 	PlayerOwner.KillPlayer(TEMP_DeathDissolveEffect);
		// }

		DissolveEffect_Inst.Deactivate();
		DissolveEffect_Inst.DestroyComponent(Owner);

		Material::SetScalarParameterValue(GlobalDissolveParams, n"DissolveRadius", 0);
		Material::SetVectorParameterValue(GlobalDissolveParams, n"DissolveLocation", FLinearColor(FVector::ZeroVector));

		HazeOwner.StopSlotAnimationByAsset(SlotParams.Animation);
		HazeOwner.UnblockCapabilities(CapabilityTags::Movement, Instigator = this);
	}

	void UpdateDissolve(const float Dt)
	{
		if(DissolveEffect_Inst == nullptr)
			return;

		ElapsedDissolveTime += Dt;

		const float DissolveAlpha = Math::Clamp(ElapsedDissolveTime / DissolveDuration, 0, 1);
		const float DissolveRadius = DissolveAlpha * DissolveMaxRadius;

		const FVector DissolveOrigin = DissolveEffect_Inst.GetWorldLocation();

		DissolveEffect_Inst.SetNiagaraVariableFloat("DissolveRadius", DissolveRadius);

		Material::SetScalarParameterValue(GlobalDissolveParams, n"DissolveRadius", DissolveRadius);
		Material::SetVectorParameterValue(GlobalDissolveParams, n"DissolveLocation", FLinearColor(DissolveOrigin));

		// trigger end dissolve 
		if(ElapsedDissolveTime >= DissolveDuration)
		{
			bDesolveRequested = false;
		}

	}

	void TriggerKnockdown(FVector DissolveOrigin)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HazeOwner);
		if(Player != nullptr)
		{
			FVector DirToOwner = (HazeOwner.ActorCenterLocation - DissolveOrigin).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			float Dot = Owner.GetActorRightVector().DotProduct(DirToOwner);
			float KnockdownDir = Dot >= 0 ? 1.0 : -1.0;

			FKnockdown Knockdown;
			Knockdown.Move = Owner.GetActorRightVector() * KnockdownDir * 300.0;
			Knockdown.Duration = DissolveDuration;
			Knockdown.StandUpDuration = 0;
			Player.ApplyKnockdown(Knockdown);
		}
	}
}

UCLASS()
class UTestDissolveCapability : UHazeCapability
{
	UTestDissolveComponent DissolveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DissolveComp = UTestDissolveComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DissolveComp.bDesolveRequested == false)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DissolveComp.bDesolveRequested)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DissolveComp.ActivateDissolve();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DissolveComp.DeactivateDissolve();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DissolveComp.UpdateDissolve(DeltaTime);
	}

}