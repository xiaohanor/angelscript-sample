
UCLASS(Abstract)
class UTreeGuardianLifeGivingEffectEventHandler : UTreeGuardianBaseEffectEventHandler
{
	float RangedLifeGive_TimeStampStarted = -1.0;
	float RangedLifeGive_TimeStampCanceled = -1.0;
	float RangedLifeGive_GrowInDuration = -1.0;

	UPROPERTY()
	UNiagaraSystem Asset_LifeGive;

	UNiagaraComponent LifeGiveAttachmentComp_Left;
	UNiagaraComponent LifeGiveAttachmentComp_Right;

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		RangedLifeGiver_DeactivateImmediately();
		LifeGive_DeactivateImmediately();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

		// UHazeSkeletalMeshComponentBase Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);

		// PrintToScreen("Mesh: " + Mesh);

		// auto RH = Mesh.GetSocketLocation(n"RightHand");
		// auto SocketNames = Mesh.GetAllSocketNames();

		// for(int i = 20; i > 0; --i)
		// {
		// 	FVector P;
		// 	FVector T = RH + Math::GetRandomPointOnSphere()*100;
		// 	Mesh.GetClosestPointOnCollision(T, P, n"RightHand");

		// 	// FVector N;
		// 	// FName BName;
		// 	// float32 D;
		// 	// Mesh.GetClosestPointOnPhysicsAsset(T, P, N, BName, D);

		// 	// Debug::DrawDebugSphere(P, 50);
		// 	Debug::DrawDebugPoint(P, 100, FLinearColor::Red);
		// 	PrintToScreen("" + P);
		// }


		// UpdateRangedLifeGiver(DeltaTime);
	}

    // Called when we transform into the tree guardian
	UFUNCTION(BlueprintOverride)
    void OnTransformedInto(FTundraPlayerTreeGuardianTransformParams Params) override
	{
		Super::OnTransformedInto(Params);

		RangedLifeGiver_DeactivateImmediately();
		LifeGive_DeactivateImmediately();
	}

 	// Called when we transform back into human form
	UFUNCTION(BlueprintOverride)
    void OnTransformedOutOf(FTundraPlayerTreeGuardianTransformParams Params) 
	{
		Super::OnTransformedOutOf(Params);

		RangedLifeGiver_DeactivateImmediately();
		LifeGive_DeactivateImmediately();
	}

	// Called when the roots should start growing from the tree guardian's hands towards the target
	UFUNCTION(BlueprintOverride)
	void OnStartGrowingOutRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params) 
	{
		Super::OnStartGrowingOutRangedInteractionRoots(Params);

		if(Params.InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive)
		{
			HandleStartGrowingOutRoots(Params.RootsOriginPoint, Params.RootsTargetPoint, Params.GrowTime);
		}
	}

	// Called when the tree guardian has started life giving (as soon as it can actually interact with the life receiving component)
	UFUNCTION(BlueprintOverride)
	void OnLifeGivingStarted(FTundraPlayerTreeGuardianLifeGivingEffectParams Params) 
	{
		Super::OnLifeGivingStarted(Params);

		if(Params.LifeGivingType == ETundraPlayerTreeGuardianLifeGivingType::Ranged)
		{
			RangedLifeGive_TimeStampStarted = Time::GetGameTimeSeconds();
			RangedLifeGive_TimeStampCanceled = -1.0;
			RangedLifeGive_GrowInDuration = -1.0;
			RangedLifeGiver_Activate();
			UpdateRangedLifeGiver(0.0);
		}
	}

	// Called when the roots should start growing back into the tree guardian's hands from being attached at the target
	UFUNCTION(BlueprintOverride)
	void OnStartGrowingInRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params) 
	{
		Super::OnStartGrowingInRangedInteractionRoots(Params);

		if(Params.InteractionType == ETundraTreeGuardianRangedInteractionType::LifeGive)
		{
			RangedLifeGive_GrowInDuration = Params.GrowTime;
			RangedLifeGive_TimeStampCanceled = Time::GetGameTimeSeconds();
		}
	}

	// Called when the tree guardian exits life giving
	UFUNCTION(BlueprintOverride)
	void OnLifeGivingStopped(FTundraPlayerTreeGuardianLifeGivingEffectParams Params) 
	{
		Super::OnLifeGivingStopped(Params);

		if(Params.LifeGivingType == ETundraPlayerTreeGuardianLifeGivingType::Ranged)
		{
			RangedLifeGiver_Deactivate();
		}
		else if(Params.LifeGivingType == ETundraPlayerTreeGuardianLifeGivingType::NonRanged)
		{
			LifeGive_Deactivate();
		}
	}

	// Called with an anim notify when tree guardian actually puts his hand into the earth and starts life giving
	UFUNCTION(BlueprintOverride)
	void OnNonRangedLifeGivingHandsTouchEarth() 
	{
		Super::OnNonRangedLifeGivingHandsTouchEarth();

		SpawnLifeGive();
	}

	// Called when the tree guardian started entering life giving (as soon as the player presses RT)
	UFUNCTION(BlueprintOverride)
	void OnLifeGivingEntering(FTundraPlayerTreeGuardianLifeGivingEffectParams Params) 
	{
		Super::OnLifeGivingEntering(Params);
	}

	UNiagaraComponent GetRangedLifeGiverVFX_RightHand() const
	{
		return TreeGuardianActor.GetRangedLifeGiverVFX_RightHand();
	}

	// UNiagaraComponent GetRangedLifeGiverVFX_Chest() const
	// {
	// 	return TreeGuardianActor.GetRangedLifeGiverVFX_Chest();
	// }

	// UNiagaraComponent GetRangedLifeGiverVFX_LeftHand() const
	// {
	// 	return TreeGuardianActor.GetRangedLifeGiverVFX_LeftHand();
	// }

	void RangedLifeGiver_Activate()
	{
		GetRangedLifeGiverVFX_RightHand().Activate(true);
		// GetRangedLifeGiverVFX_Chest().Activate(true);
		// GetRangedLifeGiverVFX_LeftHand().Activate(true);
	}

	void RangedLifeGiver_Deactivate()
	{
		GetRangedLifeGiverVFX_RightHand().Deactivate();
		// GetRangedLifeGiverVFX_Chest().Deactivate();
		// GetRangedLifeGiverVFX_LeftHand().Deactivate();
	}

	void RangedLifeGiver_DeactivateImmediately()
	{
		GetRangedLifeGiverVFX_RightHand().DeactivateImmediate();
		// GetRangedLifeGiverVFX_Chest().DeactivateImmediate();
		// GetRangedLifeGiverVFX_LeftHand().DeactivateImmediate();
	}

	void HandleStartGrowingOutRoots( USceneComponent OriginPoint, USceneComponent TargetPoint, float GrowTime) 
	{
	}

	void SpawnLifeGive()
	{
		// devCheck(LifeGiveAttachmentComp_Left == nullptr);
		// devCheck(LifeGiveAttachmentComp_Right == nullptr);

		LifeGive_Destroy();

		if(Asset_LifeGive == nullptr)
			return;

		LifeGiveAttachmentComp_Left = Niagara::SpawnLoopingNiagaraSystemAttached(
			Asset_LifeGive,
			TreeGuardianActor.GrappleLeftRootsOrigin
		);

		FQuat RefQuat = TreeGuardianActor.GrappleLeftRootsOrigin.GetWorldRotation().Quaternion();
		FQuat DesQuat = FQuat::MakeFromZX(FVector::UpVector, -RefQuat.ForwardVector);
		LifeGiveAttachmentComp_Left.SetWorldRotation(DesQuat);

		LifeGiveAttachmentComp_Right = Niagara::SpawnLoopingNiagaraSystemAttached(
			Asset_LifeGive,
			TreeGuardianActor.GrappleRightRootsOrigin
		);

		RefQuat = TreeGuardianActor.GrappleRightRootsOrigin.GetWorldRotation().Quaternion();
		DesQuat = FQuat::MakeFromZX(FVector::UpVector, -RefQuat.ForwardVector);
		LifeGiveAttachmentComp_Right.SetWorldRotation(DesQuat);

		// const FRotator SpawnOrientation = FRotator::MakeFromZ(FVector::UpVector);
		// LifeGiveAttachmentComp_Left.SetWorldRotation(SpawnOrientation);
		// LifeGiveAttachmentComp_Right.SetWorldRotation(SpawnOrientation);
	}

	void LifeGive_Deactivate()
	{
		if(LifeGiveAttachmentComp_Left != nullptr)
			LifeGiveAttachmentComp_Left.Deactivate();

		if(LifeGiveAttachmentComp_Right != nullptr)
			LifeGiveAttachmentComp_Right.Deactivate();
	}

	void LifeGive_DeactivateImmediately()
	{
		if(LifeGiveAttachmentComp_Left != nullptr)
		{
			LifeGiveAttachmentComp_Left.DeactivateImmediate();
		}

		if(LifeGiveAttachmentComp_Right != nullptr)
		{
			LifeGiveAttachmentComp_Right.DeactivateImmediate();
		}
	}

	void LifeGive_Destroy()
	{
		if(LifeGiveAttachmentComp_Left != nullptr)
		{
			LifeGiveAttachmentComp_Left.DestroyComponent(this);
		}

		if(LifeGiveAttachmentComp_Right != nullptr)
		{
			LifeGiveAttachmentComp_Right.DestroyComponent(this);
		}
	}

	void UpdateRangedLifeGiverFor(UNiagaraComponent RangedLifeGiverVFX, const float Dt)
	{
		if(RangedLifeGiverVFX.IsActive() == false)
			return;

		// TArray<FVector> StartLocations;
		// UHazeSkeletalMeshComponentBase Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		// auto RH = Mesh.GetSocketLocation(n"RightHand");
		// // Mesh.GetClosestPointOnCollision(RH + Math::GetRandomPointOnSphere() * 0, RH, n"RightHand");
		// auto LH = Mesh.GetSocketLocation(n"LeftHand");
		// // Mesh.GetClosestPointOnCollision(LH + Math::GetRandomPointOnSphere() * 0, LH, n"LeftHand");
		// auto Spine3 = Mesh.GetSocketLocation(n"Spine3");
		// // Mesh.GetClosestPointOnCollision(Spine3 + Math::GetRandomPointOnSphere() * 0, Spine3, n"Spine3");
		// StartLocations.Add(RH);
		// StartLocations.Add(LH);
		// StartLocations.Add(Spine3);
		// const int Index = Math::RandRange(0, StartLocations.Num()-1);
		// const FVector Bezier_Start = StartLocations[Index];
		// PrintToScreen("Index: " + Index);

		const FVector Bezier_Start = RangedLifeGiverVFX.GetWorldLocation();
		const FVector Bezier_End = TreeGuardianComp.CurrentRangedLifeGivingRootEndLocation;
		RangedLifeGiverVFX.SetNiagaraVariableVec3("BezierStart", Bezier_Start);
		RangedLifeGiverVFX.SetNiagaraVariableVec3("BezierEnd", Bezier_End);

		const FVector BezierDelta = Bezier_End - Bezier_Start;

		FVector Bezier_EndTangent = Bezier_End + BezierDelta.GetSafeNormal();
		if(TreeGuardianComp.RootsDestination != nullptr)
		{
			Bezier_EndTangent += TreeGuardianComp.RootsDestination.UpVector*BezierDelta.Size()*0.2;
		}
		else
		{
			Bezier_EndTangent += BezierDelta.GetSafeNormal();
		}

		RangedLifeGiverVFX.SetNiagaraVariableVec3("BezierEndTangent", Bezier_EndTangent);

		const float VerticalAlpha = GetLifeGivingVerticalAlpha();
		const float HorizontalAlpha = GetLifeGivingHorizontalAlpha();

		const float OffsetAmount_Forward = 500.0;
		const float OffsetAmount_Right = 500.0;
		const float OffsetAmount = 500.0;

		const FQuat LifeGiveHandQuat = RangedLifeGiverVFX.ComponentQuat;
		// const FVector RotationAxis_Forward = BezierDelta.GetSafeNormal();
		FVector RotationAxis_Forward = LifeGiveHandQuat.UpVector;
		const FVector RotationAxis_Right = LifeGiveHandQuat.RightVector;
		const FVector RotationAxis_Up = -LifeGiveHandQuat.ForwardVector;
		// FVector RotationAxis_Forward = (Bezier_End-Bezier_Start).GetSafeNormal();
		// FVector RotationAxis_Right = TreeGuardianActor.GetActorUpVector().CrossProduct(RotationAxis_Forward).GetSafeNormal();
		// FVector RotationAxis_Up = RotationAxis_Forward.CrossProduct(RotationAxis_Right).GetSafeNormal();

		// Debug::DrawDebugArrow(Bezier_Start, Bezier_Start + RotationAxis_Right * 1000.0, 100.0, FLinearColor::Green);
		// Debug::DrawDebugArrow(Bezier_Start, Bezier_Start + RotationAxis_Forward * 1000.0, 100.0, FLinearColor::Red);
		// Debug::DrawDebugArrow(Bezier_Start, Bezier_Start + RotationAxis_Up * 1000.0, 100.0, FLinearColor::Blue);

		RangedLifeGiverVFX.SetNiagaraVariableFloat("InputAlpha", Math::Max(Math::Abs(VerticalAlpha), Math::Abs(HorizontalAlpha)));

		// Debug::DrawDebugCoordinateSystem(
		// 	Bezier_Start,
		// 	RangedLifeGiverVFX.GetWorldRotation(),
		// 	1000,10,0
		// );

		const float MaxVerticalDisplacement = Math::Abs(BezierDelta.DotProduct(RotationAxis_Up));
		const float MaxHorizontalDisplacement = Math::Abs(BezierDelta.DotProduct(RotationAxis_Right));

		const FVector TangentOffset_Up = RotationAxis_Up * VerticalAlpha * MaxVerticalDisplacement * 0.0;
		const FVector TangentOffset_Right = RotationAxis_Right * HorizontalAlpha * MaxHorizontalDisplacement * 0.0;
		const FVector TangentOffset_Forward = RotationAxis_Forward * BezierDelta.Size() * 0.5;

		FVector Bezier_StartTangent = Bezier_Start;
		Bezier_StartTangent += TangentOffset_Forward;
		Bezier_StartTangent += TangentOffset_Right;
		Bezier_StartTangent += TangentOffset_Up;

		// Debug::DrawDebugSphere(Bezier_StartTangent, 100, 64, FLinearColor::Red);

		RangedLifeGiverVFX.SetNiagaraVariableVec3("BezierStartTangent", Bezier_StartTangent);
		
		// if(RangedLifeGive_GrowInDuration > 0.0)
		// {
		// 	const float ElapsedTime = Time::GetGameTimeSince(RangedLifeGive_TimeStampCanceled);
		// 	if(ElapsedTime > RangedLifeGive_GrowInDuration)
		// 	{
		// 		RangedLifeGive_DeactivateImmediately();
		// 	}
		// }

	}

	void UpdateRangedLifeGiver(const float Dt) 
	{
		UpdateRangedLifeGiverFor(GetRangedLifeGiverVFX_RightHand(), Dt);
		// UpdateRangedLifeGiverFor(GetRangedLifeGiverVFX_LeftHand(), Dt);
		// UpdateRangedLifeGiverFor(GetRangedLifeGiverVFX_Chest(), Dt);
	}

}
