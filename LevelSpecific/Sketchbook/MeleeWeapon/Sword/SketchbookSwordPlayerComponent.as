UCLASS(Abstract)
class USketchbookSwordPlayerComponent : USketchbookMeleeWeaponPlayerComponent
{
    UPROPERTY(EditDefaultsOnly)
	UStaticMesh SwordMesh;

    UPROPERTY(EditDefaultsOnly)
	UMaterialInterface SwordMaterial;

	UStaticMeshComponent SwordMeshComponent;

	UPROPERTY()
	UForceFeedbackEffect SwingFF;

	UPROPERTY(EditDefaultsOnly, Category = Audio)
	UHazeAudioEvent MigganSwordSwingEvent;
	
	UPROPERTY(EditDefaultsOnly, Category = Audio)
	UHazeAudioEvent ZugganSwordSwingEvent;

	void EquipWeapon() override
	{
		Super::EquipWeapon();
		SwordMeshComponent = UStaticMeshComponent::Create(Player);
        SwordMeshComponent.StaticMesh = SwordMesh;
        SwordMeshComponent.CollisionEnabled = ECollisionEnabled::NoCollision;
        SwordMeshComponent.SetCollisionProfileName(n"NoCollision");
        SwordMeshComponent.SetGenerateOverlapEvents(false);
        SwordMeshComponent.AddTag(ComponentTags::HideOnCameraOverlap);
		
		for (int i = 0; i < SwordMeshComponent.Materials.Num(); i++)
			SwordMeshComponent.SetMaterial(i, SwordMaterial);

		SwordMeshComponent.SetCustomDepthStencilValue(Player.Mesh.CustomDepthStencilValue);
		SwordMeshComponent.SetRenderCustomDepth(Player.Mesh.bRenderCustomDepth);

        SwordMeshComponent.AttachToComponent(Player.Mesh, Sketchbook::Melee::MeleeAttachSocket);
        SwordMeshComponent.SetRelativeLocationAndRotation(FVector(0.0, 0.0, 0.0), FRotator(0.0, 0.0, -90.0));
	}

	void UnequipWeapon() override
	{
		Super::UnequipWeapon();
		SwordMeshComponent.DestroyComponent(Player);
		SwordMeshComponent = nullptr;
	}

	FVector GetWeaponAttackLocation() override
	{
		return SwordMeshComponent.WorldLocation;
	}

	void OnAttack(FSketchbookMeleeAttackData AttackData) override
	{
		Super::OnAttack(AttackData);

		Player.SetActorHorizontalAndVerticalVelocity(
			AttackData.AttackDirection * ForwardImpulse,
			Player.ActorVelocity.ProjectOnToNormal(FVector::UpVector)
		);

		auto AudioEvent = Player.IsMio() ? MigganSwordSwingEvent : ZugganSwordSwingEvent;
		Audio::PostEventOnPlayer(Player, AudioEvent);
		Player.PlayForceFeedback(SwingFF,false,false,this,1);
	}
};