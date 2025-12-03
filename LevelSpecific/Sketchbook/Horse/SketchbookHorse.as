UCLASS(Abstract)
class ASketchbookHorse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRootComp;

	UPROPERTY(DefaultComponent, Attach = MeshRootComp)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Hips)
	UPerchPointComponent PerchPointComp;
	default PerchPointComp.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchZoneComp;
	default PerchZoneComp.Shape.SphereRadius = 20;


	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent CallbackComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnStartedPerch");
		PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnStopPerch");

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"ForceEnterPerch");

		// Copy same stencil value as the owner
		AHazePlayerCharacter Parent = Cast<AHazePlayerCharacter>(GetAttachParentActor());
		if (Parent != nullptr)
		{
			// const auto StencilEffectComp = USketchbookStencilEffectComponent::Get(Parent);
			// if (StencilEffectComp != nullptr)
			// 	StencilEffect::ApplyStencilEffect(Mesh, Parent, StencilEffectComp.OutlineDataAssetMio, this, EInstigatePriority::High);
			Mesh.SetRenderCustomDepth(true);
			Mesh.CustomDepthStencilValue = Parent.Mesh.CustomDepthStencilValue;
		}
	}


	UFUNCTION()
	private void ForceEnterPerch(AHazePlayerCharacter Player)
	{
		if(Player.ActorLocation.Z < PlayerTrigger.WorldLocation.Z)
			return;

		if(Player.ActorVelocity.Z <= 0)
		{
			UPlayerPerchComponent::Get(Player).StartPerching(PerchPointComp, true);
		}
	}

	UFUNCTION()
	private void OnStartedPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		UPlayerJumpSettings::SetPerchImpulse(Player, 1000, this);
		UPlayerJumpSettings::SetHorizontalPerchImpulseMultiplier(Player, 0.5, this);
	}

	UFUNCTION()
	private void OnStopPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		UPlayerJumpSettings::ClearPerchImpulse(Player, this);
		UPlayerJumpSettings::ClearHorizontalPerchImpulseMultiplier(Player, this);
	}

};