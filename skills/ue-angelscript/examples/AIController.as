// Example: AI Controller with behavior tree integration and perception
class AMyAIController : AAIController
{
    UPROPERTY(DefaultComponent)
    UAIPerceptionComponent PerceptionComponent;
    
    UPROPERTY(DefaultComponent)
    UPawnSensingComponent PawnSensing;
    
    UPROPERTY()
    UBehaviorTree BehaviorTree;
    
    UPROPERTY()
    AActor TargetActor;
    
    UPROPERTY()
    FVector PatrolCenter;
    
    UPROPERTY()
    float PatrolRadius = 1000.0f;
    
    UPROPERTY()
    float AttackRange = 500.0f;
    
    UFUNCTION(BlueprintOverride)
    void OnPossess(APawn InPawn)
    {
        Super::OnPossess(InPawn);
        
        PatrolCenter = InPawn.GetActorLocation();
        
        // Setup perception
        PerceptionComponent.OnPerceptionUpdated.AddUFunction(this, n"HandlePerceptionUpdated");
        
        // Start behavior tree
        if (BehaviorTree != nullptr)
        {
            RunBehaviorTree(BehaviorTree);
        }
        
        // Start patrol
        StartPatrol();
    }
    
    UFUNCTION()
    void HandlePerceptionUpdated(TArray<AActor> UpdatedActors)
    {
        for (AActor Actor : UpdatedActors)
        {
            if (IsPlayer(Actor))
            {
                FActorPerceptionBlueprintInfo Info;
                PerceptionComponent.GetActorsPerception(Actor, Info);
                
                if (Info.LastSensedStimuli.Num() > 0 && 
                    Info.LastSensedStimuli[0].WasSuccessfullySensed())
                {
                    SetTarget(Actor);
                }
                else
                {
                    ClearTarget();
                }
            }
        }
    }
    
    UFUNCTION()
    void SetTarget(AActor NewTarget)
    {
        if (TargetActor == NewTarget)
            return;
            
        TargetActor = NewTarget;
        GetBlackboardComponent().SetValueAsObject(n"TargetActor", TargetActor);
        
        OnTargetChanged.Broadcast(TargetActor);
    }
    
    UFUNCTION()
    void ClearTarget()
    {
        TargetActor = nullptr;
        GetBlackboardComponent().ClearValue(n"TargetActor");
    }
    
    UFUNCTION(BlueprintPure)
    bool HasTarget() const
    {
        return TargetActor != nullptr && !TargetActor.IsPendingKill();
    }
    
    UFUNCTION()
    void StartPatrol()
    {
        FVector NewLocation = GetRandomPatrolPoint();
        MoveToLocation(NewLocation, -1.0f, true, true);
    }
    
    UFUNCTION()
    FVector GetRandomPatrolPoint()
    {
        FVector2D RandomPoint = FMath::RandPointInCircle(PatrolRadius);
        return PatrolCenter + FVector(RandomPoint.X, RandomPoint.Y, 0);
    }
    
    UFUNCTION(BlueprintOverride)
    void OnMoveCompleted(FAIRequestID RequestID, TEnumAsByte<EPathFollowingResult::Type> Result)
    {
        Super::OnMoveCompleted(RequestID, Result);
        
        if (!HasTarget())
        {
            // Continue patrolling
            System::SetTimer(this, n"StartPatrol", 2.0f, false);
        }
    }
    
    UFUNCTION(BlueprintCallable)
    void ChaseTarget()
    {
        if (!HasTarget())
            return;
            
        MoveToActor(TargetActor, AttackRange - 100.0f, true, true);
    }
    
    UFUNCTION(BlueprintCallable)
    bool IsInAttackRange() const
    {
        if (!HasTarget())
            return false;
            
        float Distance = GetPawn().GetDistanceTo(TargetActor);
        return Distance <= AttackRange;
    }
    
    UFUNCTION(BlueprintCallable)
    void Attack()
    {
        if (!IsInAttackRange())
            return;
            
        // Perform attack
        OnAttack.Broadcast();
        
        // Deal damage to target
        AMyCharacter TargetCharacter = Cast<AMyCharacter>(TargetActor);
        if (TargetCharacter != nullptr)
        {
            TargetCharacter.TakeDamage(10.0f, GetPawn());
        }
    }
    
    UFUNCTION(BlueprintPure)
    bool IsPlayer(AActor Actor) const
    {
        return Actor.IsA(APlayerCharacter::StaticClass());
    }
    
    // Delegates
delegate void FOnTargetChanged(AActor NewTarget);
delegate void FOnAttack();
    
    FOnTargetChanged OnTargetChanged;
    FOnAttack OnAttack;
}
