class UReplaceStaticMeshActorWithAmbientMovementMenuExtension : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorGeneral";
	default ExtensionOrder = EScriptEditorMenuExtensionOrder::After;

	/**
	 * If we want to support more actors than AStaticMeshActor, add those here and in "GetStaticMeshComponent()"
	 */
	default SupportedClasses.Add(AStaticMeshActor);

	/**
	 * Replaces a StaticMeshActor with a AmbientMovement actor.
	 * If a RotatingMovementComponent is attached, we will attempt to copy over the rotation speeds to the AmbientMovement actor.
	 * 
	 * NOTE:
	 * - The main mesh, materials, transform and collision on/off will be copied.
	 * - RotatingMovementComponent settings will be copied. (The rotation on AmbientMovement is around one axis, so any rotation that is not on only one axis (roll, pitch or yaw) may be wrongly represented after replacing.)
	 * - DisableComponent settings will be copied.
	 * - Attempts to replace references.
	 * - Any other attached components will be lost!
	 */
	UFUNCTION(CallInEditor, meta = (EditorIcon = "Icons.ReplaceActor"))
	void ReplaceStaticMeshActorWithAmbientMovement()
	{
		TArray<AActor> SelectedActors = Editor::SelectedActors;
		TArray<AActor> NewActors;
		NewActors.Reserve(SelectedActors.Num());

		for(AActor SelectedActor : SelectedActors)
		{
			const UStaticMeshComponent StaticMeshComp = GetStaticMeshComponent(SelectedActor);
			if(StaticMeshComp == nullptr)
				continue;

			auto AmbientMovement = AAmbientMovement::Spawn(SelectedActor.ActorLocation, SelectedActor.ActorRotation, SelectedActor.Name, true, SelectedActor.Level);
			NewActors.Add(AmbientMovement);

			// Copy the StaticMeshComponent settings
			CopyStaticMeshComponent(AmbientMovement, StaticMeshComp);

			auto RotatingMovementComp = URotatingMovementComponent::Get(SelectedActor);
			if(RotatingMovementComp != nullptr)
				CopyFromRotatingMovementComponent(AmbientMovement, RotatingMovementComp);

			auto DisableComponent = UDisableComponent::Get(SelectedActor);
			if(DisableComponent != nullptr)
				CopyDisableComponent(AmbientMovement, DisableComponent);

			// Setup AmbientMovement settings
			AmbientMovement.bAffectsNavigation = false;
			CopyCollision(AmbientMovement, StaticMeshComp);

			FinishSpawningActor(AmbientMovement);

			AmbientMovement.AttachToComponent(SelectedActor.RootComponent.AttachParent, SelectedActor.RootComponent.AttachSocketName);
			AmbientMovement.SetActorRelativeTransform(SelectedActor.ActorRelativeTransform);
			AmbientMovement.SetFolderPath(SelectedActor.FolderPath);
			const FString Label = SelectedActor.GetActorLabel();

			Editor::ReplaceAllActorReferences(SelectedActor, AmbientMovement);
			SelectedActor.DestroyActor();

			AmbientMovement.SetActorLabel(Label);
		}

		if(!NewActors.IsEmpty())
			Editor::SelectActors(NewActors);
	}

	/**
	 * If we want to support more actors than AStaticMeshActor, add those here and in "SupportedClasses"
	 */
	const UStaticMeshComponent GetStaticMeshComponent(AActor Actor) const
	{
		AStaticMeshActor StaticMeshActor = Cast<AStaticMeshActor>(Actor);
		if(StaticMeshActor != nullptr)
			return StaticMeshActor.StaticMeshComponent;

		return UStaticMeshComponent::Get(Actor);
	}

	void CopyFromRotatingMovementComponent(AAmbientMovement AmbientMovement, const URotatingMovementComponent RotatingMovementComp) const
	{
		int RotatingAxes = 0;
		if(!Math::IsNearlyZero(RotatingMovementComp.RotationRate.Roll))
			RotatingAxes++;
		if(!Math::IsNearlyZero(RotatingMovementComp.RotationRate.Pitch))
			RotatingAxes++;
		if(!Math::IsNearlyZero(RotatingMovementComp.RotationRate.Yaw))
			RotatingAxes++;

		if(RotatingAxes == 1)
		{
			// Idk how to represent a rotator as an axis and angle if more than one axis has values, so just do this
			if(!Math::IsNearlyZero(RotatingMovementComp.RotationRate.Roll))
			{
				AmbientMovement.RotateAxis = FVector::ForwardVector;
				AmbientMovement.RotateSpeed = RotatingMovementComp.RotationRate.Roll;
			}
			else if(!Math::IsNearlyZero(RotatingMovementComp.RotationRate.Pitch))
			{
				AmbientMovement.RotateAxis = FVector::RightVector;
				AmbientMovement.RotateSpeed = RotatingMovementComp.RotationRate.Pitch;
			}
			else if(!Math::IsNearlyZero(RotatingMovementComp.RotationRate.Yaw))
			{
				AmbientMovement.RotateAxis = FVector::UpVector;
				AmbientMovement.RotateSpeed = RotatingMovementComp.RotationRate.Yaw;
			}
		}
		else
		{
			RotatingMovementComp.RotationRate.Quaternion().ToAxisAndAngle(AmbientMovement.RotateAxis, AmbientMovement.RotateSpeed);
			AmbientMovement.RotateSpeed = Math::RadiansToDegrees(AmbientMovement.RotateSpeed);
		}

		// RotatingMovementComponent always uses local space
		AmbientMovement.RotateLocalSpace = true;
	}

	void CopyStaticMeshComponent(AAmbientMovement AmbientMovement, const UStaticMeshComponent StaticMeshComp) const
	{
		AmbientMovement.Mesh = StaticMeshComp.StaticMesh;

		for(int i = 0; i < StaticMeshComp.NumMaterials; i++)
			AmbientMovement.ActualMesh.SetMaterial(i, StaticMeshComp.GetMaterial(i));
	}

	void CopyCollision(AAmbientMovement AmbientMovement, const UStaticMeshComponent StaticMeshComp) const
	{
		bool bNoCollision = false;
		if(!StaticMeshComp.Owner.ActorEnableCollision)
			bNoCollision = true;
		else if(!StaticMeshComp.IsCollisionEnabled())
			bNoCollision = true;

		if(bNoCollision)
			AmbientMovement.bCollisionEnabled = false;
	}

	void CopyDisableComponent(AAmbientMovement AmbientMovement, const UDisableComponent DisableComp) const
	{
		AmbientMovement.DisableComp.CopyFrom(DisableComp);
	}
};