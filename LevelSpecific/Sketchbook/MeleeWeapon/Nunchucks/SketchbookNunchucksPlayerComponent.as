UCLASS(Abstract)
class USketchbookNunchucksPlayerComponent : USketchbookMeleeWeaponPlayerComponent
{
    UPROPERTY(EditDefaultsOnly)
	USkeletalMesh NunchucksMesh;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeAnimInstanceBase> NunchucksAnimBP;

	UHazeSkeletalMeshComponentBase NunchucksMeshComp;

	UPROPERTY()
	UForceFeedbackEffect SwingFF;

	UPROPERTY(EditDefaultsOnly, Category = Audio)
	UHazeAudioEvent MioNunchuckSwingEvent;
	
	UPROPERTY(EditDefaultsOnly, Category = Audio)
	UHazeAudioEvent ZoeNunchuckSwingEvent;

	void EquipWeapon() override
	{
		Super::EquipWeapon();
		NunchucksMeshComp = UHazeSkeletalMeshComponentBase::Create(Player);
        NunchucksMeshComp.SkeletalMeshAsset = NunchucksMesh;
        NunchucksMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
        NunchucksMeshComp.SetCollisionProfileName(n"NoCollision");
        NunchucksMeshComp.SetGenerateOverlapEvents(false);
        NunchucksMeshComp.AddTag(ComponentTags::HideOnCameraOverlap);

		NunchucksMeshComp.SetAnimClass(NunchucksAnimBP);
		NunchucksMeshComp.SetCustomDepthStencilValue(Player.Mesh.CustomDepthStencilValue);
		NunchucksMeshComp.SetRenderCustomDepth(Player.Mesh.bRenderCustomDepth);

        NunchucksMeshComp.AttachToComponent(Player.Mesh, Sketchbook::Melee::MeleeAttachSocket);
	}

	void UnequipWeapon() override
	{
		Super::UnequipWeapon();
		NunchucksMeshComp.DestroyComponent(Player);
		NunchucksMeshComp = nullptr;
	}

	FVector GetWeaponAttackLocation() override
	{
		return NunchucksMeshComp.WorldLocation;
	}

	void OnAttack(FSketchbookMeleeAttackData AttackData) override
	{
		Super::OnAttack(AttackData);

		NunchucksMeshComp.SetAnimTrigger(n"Attack");
		Player.SetAnimTrigger(n"RefreshPose");

		Player.SetActorHorizontalAndVerticalVelocity(
			AttackData.AttackDirection * ForwardImpulse,
			Player.ActorVelocity.ProjectOnToNormal(FVector::UpVector)
		);

		auto AudioEvent = Player.IsMio() ? MioNunchuckSwingEvent : ZoeNunchuckSwingEvent;
		Audio::PostEventOnPlayer(Player, AudioEvent);
		Player.PlayForceFeedback(SwingFF,false,false,this,1);
	}
};