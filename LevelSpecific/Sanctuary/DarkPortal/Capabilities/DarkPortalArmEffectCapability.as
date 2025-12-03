class UDarkPortalArmEffectCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalArmEffect);

	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADarkPortalActor Portal;
	private TMap<const UDarkPortalTargetComponent, int> GrabTargetArmsCount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Portal = Cast<ADarkPortalActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Portal.SpawnedArms.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Portal.SpawnedArms.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Portal.IsGrabbingAny())
		{
			int NumArms = Portal.SpawnedArms.Num();
			int NumTargets = Portal.GetNumGrabbedComponents();
			//PrintToScreenScaled("NumTargets: " + NumTargets);

			GrabTargetArmsCount.Empty();

			int DesiredNumArmsPerTarget = NumArms;
			int NumLeftOverArms = 0;
			if (NumTargets > 1)
			{
				DesiredNumArmsPerTarget = Math::Clamp(Math::IntegerDivisionTrunc(NumArms, NumTargets), 1, NumArms);
				if (NumTargets < NumArms)
					NumLeftOverArms = NumArms % NumTargets;
			}

			TArray<UDarkPortalTargetComponent> AlreadyGrabbedCom;
			TArray<int> ArmsAlreadyGrabbingValid;

			// first determine how many arms should keep their target
			for (int i = 0; i < NumArms; ++i)
			{
				for (int j = 0; j < Portal.Grabs.Num(); j++)
				{
					const FDarkPortalUserGrab& Grab = Portal.Grabs[j];
					const UDarkPortalTargetComponent TargetComp = Portal.SpawnedArms[i].GetTargetComp();

					if (TargetComp != nullptr && Grab.TargetComponents.Contains(TargetComp) && GetDibbedArmCount(TargetComp) < DesiredNumArmsPerTarget)
					{
						if (DevTogglesDarkPortal::DebugDraw.IsEnabled())
							Debug::DrawDebugSphere(TargetComp.WorldLocation, 50, 12, ColorDebug::Rainbow(1));
						ArmsAlreadyGrabbingValid.Add(i);
						AddDibbedArm(TargetComp);
						break;
					}
				}
			}

			// then assign other arms to remaining targets
			int LeftOverArmsUsed = 0;
			for (int i = 0; i < NumArms; ++i)
			{
				if (ArmsAlreadyGrabbingValid.Contains(i))
					continue;

				for (int j = 0; j < Portal.Grabs.Num(); j++)
				{
					bool bFoundGrab = false;
					const FDarkPortalUserGrab& Grab = Portal.Grabs[j];
					for (int k = 0; k < Grab.TargetComponents.Num(); ++k)
					{
						UDarkPortalTargetComponent TargetComponent = Grab.TargetComponents[k];
						int NumArmsGrabbingComponent = GetDibbedArmCount(TargetComponent);
						if (NumArmsGrabbingComponent >= DesiredNumArmsPerTarget)
						{
							const bool AlreadyHasLeftOverArm = (NumArmsGrabbingComponent - DesiredNumArmsPerTarget) > 0;
							if (AlreadyHasLeftOverArm || LeftOverArmsUsed >= NumLeftOverArms)
								continue;
							LeftOverArmsUsed++;
						}

						// Get a grab point from the target component if available
						//  otherwise default to target component location
						FVector GrabPoint = TargetComponent.WorldLocation;
						if (TargetComponent.GrabPoints.Num() > 0)
						{
							int GrabIndex = (TargetComponent.GrabPoints.Num() - 1) - (i % TargetComponent.GrabPoints.Num());
							GrabPoint = TargetComponent.WorldTransform.TransformPositionNoScale(TargetComponent.GrabPoints[GrabIndex]);
						}

						// TODO: Arms still use grab data :^)
						auto GrabData = FDarkPortalGrabData(
							TargetComponent,
							Grab.ResponseComponent,
							GrabPoint,
							-TargetComponent.UpVector
						);
						GrabData.Timestamp = Grab.Timestamp;
						GrabData.bHasTriggeredResponse = Grab.bHasTriggeredResponse;

						Portal.SpawnedArms[i].SetTarget(GrabData);
						AddDibbedArm(Portal.SpawnedArms[i].GetTargetComp());
						bFoundGrab = true;
						break;
					}
					if (bFoundGrab)
						break;
				}
			}
		}
		else
		{
			for (auto Arm : Portal.SpawnedArms)
				Arm.SetTarget(FDarkPortalGrabData());
		}

		for (int i = 0, Count = Portal.SpawnedArms.Num(); i < Count; ++i)
			Portal.SpawnedArms[i].Update(i, DeltaTime);

		SendCompiledArmsDataToMasterNiagaraComponent();
	}

	void SendCompiledArmsDataToMasterNiagaraComponent()
	{
		// compile the arms bezier location data into arrays and send that to the master niagara component 

		TArray<FVector> VecArray_P0;
		TArray<FVector> VecArray_P1;
		TArray<FVector> VecArray_P2;
		TArray<FVector> PosArray_P3;
		VecArray_P0.Reserve(Portal.SpawnedArms.Num());
		VecArray_P1.Reserve(Portal.SpawnedArms.Num());
		VecArray_P2.Reserve(Portal.SpawnedArms.Num());
		PosArray_P3.Reserve(Portal.SpawnedArms.Num());

		for(auto& IterArm : Portal.SpawnedArms)
		{
			auto& Curve = IterArm.GetCurrentPortalCurve();
			VecArray_P0.Add(Curve.Start);
			VecArray_P1.Add(Curve.StartTangent);
			VecArray_P2.Add(Curve.EndTangent);
			PosArray_P3.Add(Curve.End);

			// Debug::DrawDebugPoint(Curve.End, 10, FLinearColor::Yellow, 0.0, false);
		}

		NiagaraDataInterfaceArray::SetNiagaraArrayVector(Portal.SpawnedArms[0], n"VecArray_P0", VecArray_P0);
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(Portal.SpawnedArms[0], n"VecArray_P1", VecArray_P1);
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(Portal.SpawnedArms[0], n"VecArray_P2", VecArray_P2);
		NiagaraDataInterfaceArray::SetNiagaraArrayPosition(Portal.SpawnedArms[0], n"PosArray_P3", PosArray_P3);
	}

	private void AddDibbedArm(const UDarkPortalTargetComponent Target) 
	{
		if (GrabTargetArmsCount.Contains(Target))
			GrabTargetArmsCount[Target] += 1;
		else
			GrabTargetArmsCount.Add(Target, 1);
	}

	private int GetDibbedArmCount(const UDarkPortalTargetComponent& Target)
	{
		if (GrabTargetArmsCount.Contains(Target))
			return GrabTargetArmsCount[Target];
		return 0;
	}

}