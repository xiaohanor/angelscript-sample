struct FSanctuaryBloodGateDarkPortalTargetEnablingData
{
	UDarkPortalTargetComponent TargetComp = nullptr;
	float Angle = 0.0;

	int opCmp(FSanctuaryBloodGateDarkPortalTargetEnablingData Other) const
	{
		if (Angle > Other.Angle)
			return 1;
		else if (Angle < Other.Angle)
			return -1;
		else
			return 0;
	}
}

class USanctuaryBloodGateDarkPortalTargetEnablingCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalTargetActiveOnBloodGate);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	TArray<FSanctuaryBloodGateDarkPortalTargetEnablingData> TargetComps;

	ASanctuaryBloodGate Gate;
	USceneComponent RotatingComp;
	UDarkPortalUserComponent PortalUserComp;
	
	int CurrentTargetIndex = -1;
	int NextTargetIndex = -1;
	bool bPortalIsRightOfDoor = true;

	AHazePlayerCharacter Zoe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Gate = Cast<ASanctuaryBloodGate>(Owner);
		if (Gate != nullptr)
		{
			TArray<UDarkPortalTargetComponent> Temp;
			Gate.GetComponentsByClass(UDarkPortalTargetComponent, Temp);
			for (UDarkPortalTargetComponent TargetComp : Temp)
			{
				USceneComponent LeftOrRightComp = TargetComp.GetAttachParent();
				if (RotatingComp == nullptr)
					RotatingComp = LeftOrRightComp.GetAttachParent();		
				TargetComp.Disable(this);
				FSanctuaryBloodGateDarkPortalTargetEnablingData TempData;
				TempData.TargetComp = TargetComp;
				float AdditionalAngle = LeftOrRightComp.GetName() == n"BigLeftComp" ? 180 : 0;
				FVector AngleVector = -TargetComp.RelativeLocation;
				AngleVector.Y = 0;
				float Degrees = Math::DotToDegrees(FVector::UpVector.DotProduct(AngleVector.GetSafeNormal()));
				if (AdditionalAngle > KINDA_SMALL_NUMBER)
					Degrees = 180 - Degrees;
				TempData.Angle = 180 - Degrees + AdditionalAngle;
				TargetComps.Add(TempData);
			}
			TargetComps.Sort(true);
		}
		DevTogglesBloodGate::DebugDrawGrabs.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TargetComps.Num() == 0)
			return false;

		if (PortalUserComp == nullptr) // note(Ylva) fulhax since PortalUserComp doesn't exist in Setup()
			return true;

		if (PortalUserComp.Portal.State != EDarkPortalState::Settle)
			return false;

		if (!PortalUserComp.Portal.bPlayerWantsGrab)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HasCurrentTarget())
			return true;

		if (PortalUserComp == nullptr)
			return true;

		if (PortalUserComp.Portal.State != EDarkPortalState::Settle)
			return true;

		if (!PortalUserComp.Portal.bPlayerWantsGrab)
			return true;

		return false;
	}

	bool HasCurrentTarget() const
	{
		return CurrentTargetIndex >= 0;
	}

	bool HasNextTarget() const
	{
		return NextTargetIndex >= 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// note(Ylva) fulhax since PortalUserComp doesn't exist in Setup()
		if (PortalUserComp == nullptr)
			PortalUserComp = UDarkPortalUserComponent::Get(Game::GetZoe());

		Zoe = Game::Zoe;

		FVector DoorMiddleToPortal = PortalUserComp.Portal.GetActorLocation() - RotatingComp.WorldLocation;
		bPortalIsRightOfDoor = DoorMiddleToPortal.DotProduct(Gate.GetActorRotation().ForwardVector) > 0.0; // note(Ylva) forward is pointing to the right :sweat:
		TryAssignGrabPoint();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (int i = 0; i < TargetComps.Num(); ++i)
			TargetComps[i].TargetComp.Disable(this);

		CurrentTargetIndex = -1;
		NextTargetIndex = -1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (int i = 0; i < TargetComps.Num(); ++i)
		{
			bool bIsDisabled = TargetComps[i].TargetComp.IsDisabledForPlayer(Zoe);
			bool bShouldBeEnabled = (i == CurrentTargetIndex || i == NextTargetIndex);
			if (bIsDisabled && bShouldBeEnabled)
			{
				TargetComps[i].TargetComp.EnableForPlayer(Zoe, this);
			}
			else if (!bIsDisabled && !bShouldBeEnabled)
			{
				TargetComps[i].TargetComp.DisableForPlayer(Zoe, this);
			}
			if (DevTogglesBloodGate::DebugDrawGrabs.IsEnabled())
			{
#if EDITOR
				FString Naming = TargetComps[i].TargetComp.GetFullName();
				FString Message = Naming.Contains("Right") ? "right " : "left ";
				Message += String::GetSubstring(Naming, Naming.Len() - 1, 1) + " ";
				if (bIsDisabled)
					Message += "disabled";
				else
					Message += "enabled";
				Debug::DrawDebugString(TargetComps[i].TargetComp.WorldLocation, Message, bIsDisabled ? ColorDebug::Red : ColorDebug::Green, 0.0, 1.5);
#endif
			}
		}

		if (HasCurrentTarget())
		{
			float TotalAngle = GetTotalAngle(TargetComps[CurrentTargetIndex]);
			if (DevTogglesBloodGate::DebugDrawGrabs.IsEnabled())
				Debug::DrawDebugSphere(TargetComps[CurrentTargetIndex].TargetComp.WorldLocation, 75, 12, FLinearColor::LucBlue);
			if (!IsWithinActiveAngle(TotalAngle))
			{
				if (NextTargetIndex >= 0)
				{
					float NextAngle = GetTotalAngle(TargetComps[NextTargetIndex]);
					if (IsWithinActiveAngle(NextAngle))
					{
						CurrentTargetIndex = NextTargetIndex;
						AssignNext();
					}
					else
					{
						CurrentTargetIndex = -1;
						TryAssignGrabPoint();
					}
				}
			}
		}

		if (HasNextTarget() && DevTogglesBloodGate::DebugDrawGrabs.IsEnabled())
			Debug::DrawDebugSphere(TargetComps[NextTargetIndex].TargetComp.WorldLocation, 50, 12, ColorDebug::White);
	}

	float GetBigRotPositiveSpaceRotation()
	{
		float PositiveSpaceBigRot = RotatingComp.RelativeRotation.Roll;
		if (PositiveSpaceBigRot < 0.0)
			PositiveSpaceBigRot += 360;
		return 360 - PositiveSpaceBigRot;
	}

	private float GetTotalAngle(FSanctuaryBloodGateDarkPortalTargetEnablingData& TargetData)
	{
		float Angle = GetBigRotPositiveSpaceRotation() + TargetData.Angle;
		if (Angle > 360)
			Angle -= 360;
		return Angle;
	}

	private bool IsWithinActiveAngle(float Angle)
	{
		if (bPortalIsRightOfDoor)
			return Angle > Gate.DarkPortalRightSideStartGrabAngle && Angle < Gate.DarkPortalRightSideStartGrabAngle + Gate.DarkPortalAllowedAngle;
		return Angle > Gate.DarkPortalLeftSideStartGrabAngle && Angle < Gate.DarkPortalLeftSideStartGrabAngle + Gate.DarkPortalAllowedAngle;
	}

	private bool IsWithinGrabAngle(float Angle)
	{
		if (bPortalIsRightOfDoor)
			return Angle > Gate.DarkPortalRightSideStartGrabAngle && Angle < Gate.DarkPortalRightSideStartGrabAngle + Gate.DarkPortalGrabNextAngle;
		return Angle > Gate.DarkPortalLeftSideStartGrabAngle && Angle < Gate.DarkPortalLeftSideStartGrabAngle + Gate.DarkPortalGrabNextAngle;
	}

	private int FindBestTargetIndex()
	{
		int BestIndex = -1;
		float BestAngle = BIG_NUMBER;
		for (int i = 0; i < TargetComps.Num(); ++i)
		{
			float TotalAngle = GetTotalAngle(TargetComps[i]);
			if (IsWithinGrabAngle(TotalAngle) && TotalAngle < BestAngle)
			{
				BestIndex = i;
				BestAngle = TotalAngle;
			}
		}
		return BestIndex;
	}

	private void TryAssignGrabPoint()
	{
		if (HasCurrentTarget())
			return;

		int BestIndex = FindBestTargetIndex();
		if (BestIndex == -1)
			return; 

		CurrentTargetIndex = BestIndex;
		AssignNext();
	}

	private void AssignNext()
	{
		NextTargetIndex = CurrentTargetIndex + 2;
		if (NextTargetIndex >= TargetComps.Num())
			NextTargetIndex = NextTargetIndex - TargetComps.Num();
		else if (NextTargetIndex < 0)
			NextTargetIndex += TargetComps.Num();
	}
}